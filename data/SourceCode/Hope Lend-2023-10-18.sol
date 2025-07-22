function executeFlashLoanSimple(
    DataTypes.ReserveData storage reserve,
    DataTypes.FlashloanSimpleParams memory params
) external {
    // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
    // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
    // This is done to protect against reentrance and rate manipulation within the user specified payload.

    ValidationLogic.validateFlashloanSimple(reserve);

    IFlashLoanSimpleReceiver receiver = IFlashLoanSimpleReceiver(
        params.receiverAddress
    );
    uint256 totalPremium = params.amount.percentMul(
        params.flashLoanPremiumTotal
    );
    IHToken(reserve.hTokenAddress).transferUnderlyingTo(
        params.receiverAddress,
        params.amount
    );

    require(
        receiver.executeOperation(
            params.asset,
            params.amount,
            totalPremium,
            msg.sender,
            params.params
        ),
        Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN
    );

    _handleFlashLoanRepayment(
        reserve,
        DataTypes.FlashLoanRepaymentParams({
            asset: params.asset,
            receiverAddress: params.receiverAddress,
            amount: params.amount,
            totalPremium: totalPremium,
            flashLoanPremiumToProtocol: params.flashLoanPremiumToProtocol,
            referralCode: params.referralCode
        })
    );
}
function _handleFlashLoanRepayment(
    DataTypes.ReserveData storage reserve,
    DataTypes.FlashLoanRepaymentParams memory params
) internal {
    uint256 premiumToProtocol = params.totalPremium.percentMul(
        params.flashLoanPremiumToProtocol
    );
    uint256 premiumToLP = params.totalPremium - premiumToProtocol;
    uint256 amountPlusPremium = params.amount + params.totalPremium;

    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);
    reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
        IERC20(reserveCache.hTokenAddress).totalSupply() +
            uint256(reserve.accruedToTreasury).rayMul(
                reserveCache.nextLiquidityIndex
            ),
        premiumToLP
    );

    reserve.accruedToTreasury += premiumToProtocol
        .rayDiv(reserveCache.nextLiquidityIndex)
        .toUint128();
    reserve.updateInterestRates(
        reserveCache,
        params.asset,
        amountPlusPremium,
        0
    );

    IERC20(params.asset).safeTransferFrom(
        params.receiverAddress,
        reserveCache.hTokenAddress,
        amountPlusPremium
    );

    ILendingGauge lendingGauge = IAbsGauge(reserveCache.hTokenAddress)
        .lendingGauge();
    if (address(lendingGauge) != address(0)) {
        lendingGauge.updateAllocation();
    }

    IHToken(reserveCache.hTokenAddress).handleRepayment(
        params.receiverAddress,
        params.receiverAddress,
        amountPlusPremium
    );

    emit FlashLoan(
        params.receiverAddress,
        msg.sender,
        params.asset,
        params.amount,
        DataTypes.InterestRateMode(0),
        params.totalPremium,
        params.referralCode
    );
}

function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
        if or(
            iszero(b),
            iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
        ) {
            revert(0, 0)
        }

        c := div(add(mul(a, RAY), div(b, 2)), b)
    }
}
