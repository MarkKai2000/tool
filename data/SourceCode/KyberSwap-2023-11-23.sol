  
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external override lock returns (int256 deltaQty0, int256 deltaQty1) {
    require(swapQty != 0, '0 swapQty');

    SwapData memory swapData;
    swapData.specifiedAmount = swapQty;
    swapData.isToken0 = isToken0;
    swapData.isExactInput = swapData.specifiedAmount > 0;
    // tick (token1Qty/token0Qty) will increase for swapping from token1 to token0
    bool willUpTick = (swapData.isExactInput != isToken0);
    (
      swapData.baseL,
      swapData.reinvestL,
      swapData.sqrtP,
      swapData.currentTick,
      swapData.nextTick
    ) = _getInitialSwapData(willUpTick);

    // cache data before swap to write into oracle if needed
    OracleCache memory oracleCache = OracleCache({
      currentTick: swapData.currentTick,
      baseL: swapData.baseL
    });

    // verify limitSqrtP
    if (willUpTick) {
      require(
        limitSqrtP > swapData.sqrtP && limitSqrtP < TickMath.MAX_SQRT_RATIO,
        'bad limitSqrtP'
      );
    } else {
      require(
        limitSqrtP < swapData.sqrtP && limitSqrtP > TickMath.MIN_SQRT_RATIO,
        'bad limitSqrtP'
      );
    }
    SwapCache memory cache;
    // continue swapping while specified input/output isn't satisfied or price limit not reached
    while (swapData.specifiedAmount != 0 && swapData.sqrtP != limitSqrtP) {
      // math calculations work with the assumption that the price diff is capped to 5%
      // since tick distance is uncapped between currentTick and nextTick
      // we use tempNextTick to satisfy our assumption with MAX_TICK_DISTANCE is set to be matched this condition

      int24 tempNextTick = swapData.nextTick;
      if (willUpTick && tempNextTick > C.MAX_TICK_DISTANCE + swapData.currentTick) {
        tempNextTick = swapData.currentTick + C.MAX_TICK_DISTANCE;
      } else if (!willUpTick && tempNextTick < swapData.currentTick - C.MAX_TICK_DISTANCE) {
        tempNextTick = swapData.currentTick - C.MAX_TICK_DISTANCE;
      }

      swapData.startSqrtP = swapData.sqrtP;
      swapData.nextSqrtP = TickMath.getSqrtRatioAtTick(tempNextTick);

      // local scope for targetSqrtP, usedAmount, returnedAmount and deltaL
      {
        uint160 targetSqrtP = swapData.nextSqrtP;
        // ensure next sqrtP (and its corresponding tick) does not exceed price limit
        if (willUpTick == (swapData.nextSqrtP > limitSqrtP)) {
          targetSqrtP = limitSqrtP;
        }

        int256 usedAmount;
        int256 returnedAmount;
        uint256 deltaL;
        (usedAmount, returnedAmount, deltaL, swapData.sqrtP) = SwapMath.computeSwapStep(
          swapData.baseL + swapData.reinvestL,
          swapData.sqrtP,
          targetSqrtP,
          swapFeeUnits,
          swapData.specifiedAmount,
          swapData.isExactInput,
          swapData.isToken0
        );

        swapData.specifiedAmount -= usedAmount;
        swapData.returnedAmount += returnedAmount;
        swapData.reinvestL += deltaL.toUint128();
      }

      // if price has not reached the next sqrt price
      if (swapData.sqrtP != swapData.nextSqrtP) {
        if (swapData.sqrtP != swapData.startSqrtP) {
          // update the current tick data in case the sqrtP has changed
          swapData.currentTick = TickMath.getTickAtSqrtRatio(swapData.sqrtP);
        }
        break;
      }
      swapData.currentTick = willUpTick ? tempNextTick : tempNextTick - 1;
      // if tempNextTick is not next initialized tick
      if (tempNextTick != swapData.nextTick) continue;

      if (cache.rTotalSupply == 0) {
        // load variables that are only initialized when crossing a tick
        cache.rTotalSupply = totalSupply();
        cache.reinvestLLast = poolData.reinvestLLast;
        cache.feeGrowthGlobal = poolData.feeGrowthGlobal;
        cache.secondsPerLiquidityGlobal = _syncSecondsPerLiquidity(
          poolData.secondsPerLiquidityGlobal,
          swapData.baseL
        );
        (cache.feeTo, cache.governmentFeeUnits) = factory.feeConfiguration();
      }
      // update rTotalSupply, feeGrowthGlobal and reinvestL
      uint256 rMintQty = ReinvestmentMath.calcrMintQty(
        swapData.reinvestL,
        cache.reinvestLLast,
        swapData.baseL,
        cache.rTotalSupply
      );
      if (rMintQty != 0) {
        cache.rTotalSupply += rMintQty;
        // overflow/underflow not possible bc governmentFeeUnits < 20000
        unchecked {
          uint256 governmentFee = (rMintQty * cache.governmentFeeUnits) / C.FEE_UNITS;
          cache.governmentFee += governmentFee;

          uint256 lpFee = rMintQty - governmentFee;
          cache.lpFee += lpFee;

          cache.feeGrowthGlobal += FullMath.mulDivFloor(lpFee, C.TWO_POW_96, swapData.baseL);
        }
      }
      cache.reinvestLLast = swapData.reinvestL;

      (swapData.baseL, swapData.nextTick) = _updateLiquidityAndCrossTick(
        swapData.nextTick,
        swapData.baseL,
        cache.feeGrowthGlobal,
        cache.secondsPerLiquidityGlobal,
        willUpTick
      );
    }

    // if the swap crosses at least 1 initalized tick
    if (cache.rTotalSupply != 0) {
      if (cache.governmentFee > 0) _mint(cache.feeTo, cache.governmentFee);
      if (cache.lpFee > 0) _mint(address(this), cache.lpFee);
      poolData.reinvestLLast = cache.reinvestLLast;
      poolData.feeGrowthGlobal = cache.feeGrowthGlobal;
    }

    // write an oracle entry if tick changed
    if (swapData.currentTick != oracleCache.currentTick) {
      poolOracle.write(_blockTimestamp(), oracleCache.currentTick, oracleCache.baseL);
    }

    _updatePoolData(
      swapData.baseL,
      swapData.reinvestL,
      swapData.sqrtP,
      swapData.currentTick,
      swapData.nextTick
    );

    (deltaQty0, deltaQty1) = isToken0
      ? (swapQty - swapData.specifiedAmount, swapData.returnedAmount)
      : (swapData.returnedAmount, swapQty - swapData.specifiedAmount);

    // handle token transfers and perform callback
    if (willUpTick) {
      // outbound deltaQty0 (negative), inbound deltaQty1 (positive)
      // transfer deltaQty0 to recipient
      if (deltaQty0 < 0) token0.safeTransfer(recipient, deltaQty0.revToUint256());

      // collect deltaQty1
      uint256 balance1Before = _poolBalToken1();
      ISwapCallback(msg.sender).swapCallback(deltaQty0, deltaQty1, data);
      require(_poolBalToken1() >= balance1Before + uint256(deltaQty1), 'lacking deltaQty1');
    } else {
      // inbound deltaQty0 (positive), outbound deltaQty1 (negative)
      // transfer deltaQty1 to recipient
      if (deltaQty1 < 0) token1.safeTransfer(recipient, deltaQty1.revToUint256());

      // collect deltaQty0
      uint256 balance0Before = _poolBalToken0();
      ISwapCallback(msg.sender).swapCallback(deltaQty0, deltaQty1, data);
      require(_poolBalToken0() >= balance0Before + uint256(deltaQty0), 'lacking deltaQty0');
    }

    emit Swap(
      msg.sender,
      recipient,
      deltaQty0,
      deltaQty1,
      swapData.sqrtP,
      swapData.baseL,
      swapData.currentTick
    );
  }
  function computeSwapStep(
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 targetSqrtP,
    uint256 feeInFeeUnits,
    int256 specifiedAmount,
    bool isExactInput,
    bool isToken0
  )
    internal
    pure
    returns (
      int256 usedAmount,
      int256 returnedAmount,
      uint256 deltaL,
      uint160 nextSqrtP
    )
  {
    // in the event currentSqrtP == targetSqrtP because of tick movements, return
    // eg. swapped up tick where specified price limit is on an initialised tick
    // then swapping down tick will cause next tick to be the same as the current tick
    if (currentSqrtP == targetSqrtP) return (0, 0, 0, currentSqrtP);
    usedAmount = calcReachAmount(
      liquidity,
      currentSqrtP,
      targetSqrtP,
      feeInFeeUnits,
      isExactInput,
      isToken0
    );

    if (
      (isExactInput && usedAmount > specifiedAmount) ||
      (!isExactInput && usedAmount <= specifiedAmount)
    ) {
      usedAmount = specifiedAmount;
    } else {
      nextSqrtP = targetSqrtP;
    }

    uint256 absDelta = usedAmount >= 0 ? uint256(usedAmount) : usedAmount.revToUint256();
    if (nextSqrtP == 0) {
      deltaL = estimateIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        feeInFeeUnits,
        isExactInput,
        isToken0
      );
      nextSqrtP = calcFinalPrice(absDelta, liquidity, deltaL, currentSqrtP, isExactInput, isToken0)
      .toUint160();
    } else {
      deltaL = calcIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        nextSqrtP,
        isExactInput,
        isToken0
      );
    }
    returnedAmount = calcReturnedAmount(
      liquidity,
      currentSqrtP,
      nextSqrtP,
      deltaL,
      isExactInput,
      isToken0
    );
  }