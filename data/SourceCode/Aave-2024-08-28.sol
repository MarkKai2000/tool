function swapAndRepay(
    IERC20Detailed collateralAsset,
    IERC20Detailed debtAsset,
    uint256 collateralAmount,
    uint256 debtRepayAmount,
    uint256 debtRateMode,
    uint256 buyAllBalanceOffset,
    bytes calldata paraswapData,
    PermitSignature calldata permitSignature
) external nonReentrant {
    debtRepayAmount = getDebtRepayAmount(
        debtAsset,
        debtRateMode,
        buyAllBalanceOffset,
        debtRepayAmount,
        msg.sender
    );

    // Pull aTokens from user
    _pullATokenAndWithdraw(
        address(collateralAsset),
        msg.sender,
        collateralAmount,
        permitSignature
    );
    //buy debt asset using collateral asset
    uint256 amountSold = _buyOnParaSwap(
        buyAllBalanceOffset,
        paraswapData,
        collateralAsset,
        debtAsset,
        collateralAmount,
        debtRepayAmount
    );

    uint256 collateralBalanceLeft = collateralAmount - amountSold;

    //deposit collateral back in the pool, if left after the swap(buy)
    if (collateralBalanceLeft > 0) {
        IERC20(collateralAsset).safeApprove(address(POOL), 0);
        IERC20(collateralAsset).safeApprove(
            address(POOL),
            collateralBalanceLeft
        );
        POOL.deposit(
            address(collateralAsset),
            collateralBalanceLeft,
            msg.sender,
            0
        );
    }

    // Repay debt. Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
    IERC20(debtAsset).safeApprove(address(POOL), 0);
    IERC20(debtAsset).safeApprove(address(POOL), debtRepayAmount);
    POOL.repay(address(debtAsset), debtRepayAmount, debtRateMode, msg.sender);
}

function _buyOnParaSwap(
    uint256 toAmountOffset,
    bytes memory paraswapData,
    IERC20Detailed assetToSwapFrom,
    IERC20Detailed assetToSwapTo,
    uint256 maxAmountToSwap,
    uint256 amountToReceive
) internal returns (uint256 amountSold) {
    (bytes memory buyCalldata, IParaSwapAugustus augustus) = abi.decode(
        paraswapData,
        (bytes, IParaSwapAugustus)
    );

    require(
        AUGUSTUS_REGISTRY.isValidAugustus(address(augustus)),
        "INVALID_AUGUSTUS"
    );

    {
        uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
        uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

        uint256 fromAssetPrice = _getPrice(address(assetToSwapFrom));
        uint256 toAssetPrice = _getPrice(address(assetToSwapTo));

        uint256 expectedMaxAmountToSwap = amountToReceive
            .mul(toAssetPrice.mul(10 ** fromAssetDecimals))
            .div(fromAssetPrice.mul(10 ** toAssetDecimals))
            .percentMul(
                PercentageMath.PERCENTAGE_FACTOR.add(MAX_SLIPPAGE_PERCENT)
            );

        require(
            maxAmountToSwap <= expectedMaxAmountToSwap,
            "maxAmountToSwap exceed max slippage"
        );
    }

    uint256 balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
    require(
        balanceBeforeAssetFrom >= maxAmountToSwap,
        "INSUFFICIENT_BALANCE_BEFORE_SWAP"
    );
    uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));

    address tokenTransferProxy = augustus.getTokenTransferProxy();
    assetToSwapFrom.safeApprove(tokenTransferProxy, 0);
    assetToSwapFrom.safeApprove(tokenTransferProxy, maxAmountToSwap);

    if (toAmountOffset != 0) {
        // Ensure 256 bit (32 bytes) toAmountOffset value is within bounds of the
        // calldata, not overlapping with the first 4 bytes (function selector).
        require(
            toAmountOffset >= 4 && toAmountOffset <= buyCalldata.length.sub(32),
            "TO_AMOUNT_OFFSET_OUT_OF_RANGE"
        );
        // Overwrite the toAmount with the correct amount for the buy.
        // In memory, buyCalldata consists of a 256 bit length field, followed by
        // the actual bytes data, that is why 32 is added to the byte offset.
        assembly {
            mstore(add(buyCalldata, add(toAmountOffset, 32)), amountToReceive)
        }
    }
    (bool success, ) = address(augustus).call(buyCalldata);
    if (!success) {
        // Copy revert reason from call
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    uint256 balanceAfterAssetFrom = assetToSwapFrom.balanceOf(address(this));
    amountSold = balanceBeforeAssetFrom - balanceAfterAssetFrom;
    require(amountSold <= maxAmountToSwap, "WRONG_BALANCE_AFTER_SWAP");
    uint256 amountReceived = assetToSwapTo.balanceOf(address(this)).sub(
        balanceBeforeAssetTo
    );
    require(amountReceived >= amountToReceive, "INSUFFICIENT_AMOUNT_RECEIVED");

    emit Bought(
        address(assetToSwapFrom),
        address(assetToSwapTo),
        amountSold,
        amountReceived
    );
}
