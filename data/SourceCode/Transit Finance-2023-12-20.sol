function _executeV3Swap(ExactInputV3SwapParams calldata params) internal nonReentrant whenNotPaused returns (uint256 returnAmount) {
  require(params.pools.length > 0, "Empty pools");
  require(params.deadline >= block.timestamp, "Expired");
  require(_wrapped_allowed[params.wrappedToken], "Invalid wrapped address");
  address tokenIn = params.srcToken;
  address tokenOut = params.dstToken;
  uint256 actualAmountIn = calculateTradeFee(true, params.amount, params.fee, params.signature);
  uint256 toBeforeBalance;
  bool isToETH;
  if (TransferHelper.isETH(params.srcToken)) {
    tokenIn = params.wrappedToken;
    require(msg.value == params.amount, "Invalid msg.value");
    TransferHelper.safeDeposit(params.wrappedToken, actualAmountIn);
  } else {
    TransferHelper.safeTransferFrom(params.srcToken, msg.sender, address(this), params.amount);
  }

  if (TransferHelper.isETH(params.dstToken)) {
    tokenOut = params.wrappedToken;
    toBeforeBalance = IERC20(params.wrappedToken).balanceOf(address(this));
    isToETH = true;
  } else {
    toBeforeBalance = IERC20(params.dstToken).balanceOf(params.dstReceiver);
  }

  {
    uint256 len = params.pools.length;
    address recipient = address(this);
    bytes memory tokenInAndPoolSalt;
    if (len > 1) {
      address thisTokenIn = tokenIn;
      address thisTokenOut = address(0);
      for (uint256 i; i < len; i++) {
        uint256 thisPool = params.pools[i];
        (thisTokenIn, tokenInAndPoolSalt) = _verifyPool(thisTokenIn, thisTokenOut, thisPool);
        if (i == len - 1 && !isToETH) {
          recipient = params.dstReceiver;
          thisTokenOut = tokenOut;
        }
        actualAmountIn = _swap(recipient, thisPool, tokenInAndPoolSalt, actualAmountIn);
      }
      returnAmount = actualAmountIn;
    } else {
      (, tokenInAndPoolSalt) = _verifyPool(tokenIn, tokenOut, params.pools[0]);
      if (!isToETH) {
        recipient = params.dstReceiver;
      }
      returnAmount = _swap(recipient, params.pools[0], tokenInAndPoolSalt, actualAmountIn);
    }
  }

  if (isToETH) {
    returnAmount = IERC20(params.wrappedToken).balanceOf(address(this)).sub(toBeforeBalance);
    require(returnAmount >= params.minReturnAmount, "Too little received");
    TransferHelper.safeWithdraw(params.wrappedToken, returnAmount);
    TransferHelper.safeTransferETH(params.dstReceiver, returnAmount);
  } else {
    returnAmount = IERC20(params.dstToken).balanceOf(params.dstReceiver).sub(toBeforeBalance);
    require(returnAmount >= params.minReturnAmount, "Too little received");
  }

  _emitTransit(params.srcToken, params.dstToken, params.dstReceiver, params.amount, returnAmount, 0, params.channel);
}