function repay(
    address asset,
    uint256 amount,
    address onBehalfOf
) external override whenNotPaused returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    uint256 variableDebt = Helpers.getUserCurrentDebt(onBehalfOf, reserve);
    address xToken = reserve.xTokenAddress;
    uint256 userBalance = IERC20(xToken).balanceOf(msg.sender);
    ValidationLogic.validateRepay(
        reserve,
        amount,
        onBehalfOf,
        variableDebt,
        userBalance
    );
}
function validateRepay(
    DataTypes.ReserveData storage reserve,
    uint256 amountSent,
    address onBehalfOf,
    uint256 variableDebt,
    uint256 userBalance
) external view {
    bool isActive = reserve.configuration.getActive();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);
    require(variableDebt > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);
    require(userBalance >= amountSent, "deposit is less than debt");
    require(
        amountSent != uint256(-1) || msg.sender == onBehalfOf,
        Errors.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );
}
