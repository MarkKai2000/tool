function deposit(
    uint256 _deposit,
    uint256 _deadline
)
    external
    deadline(_deadline)
    transactable
    nonReentrant
    notInWhitelistingStage
    returns (uint256, uint256[] memory)
{
    // (curvesMinted_,  deposits_)
    return ProportionalLiquidity.proportionalDeposit(curve, _deposit);
}

function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
)
    external
    isFlashable
    globallyTransactable
    nonReentrant
    noDelegateCall
    transactable
    isNotEmergency
{
    uint256 fee = curve.epsilon.mulu(1e18);

    require(
        IERC20(derivatives[0]).balanceOf(address(this)) > 0,
        "Curve/token0-zero-liquidity-depth"
    );
    require(
        IERC20(derivatives[1]).balanceOf(address(this)) > 0,
        "Curve/token1-zero-liquidity-depth"
    );

    uint256 fee0 = FullMath.mulDivRoundingUp(amount0, fee, 1e18);
    uint256 fee1 = FullMath.mulDivRoundingUp(amount1, fee, 1e18);

    uint256 balance0Before = IERC20(derivatives[0]).balanceOf(address(this));
    uint256 balance1Before = IERC20(derivatives[1]).balanceOf(address(this));

    if (amount0 > 0) IERC20(derivatives[0]).safeTransfer(recipient, amount0);
    if (amount1 > 0) IERC20(derivatives[1]).safeTransfer(recipient, amount1);

    IFlashCallback(msg.sender).flashCallback(fee0, fee1, data);

    uint256 balance0After = IERC20(derivatives[0]).balanceOf(address(this));
    uint256 balance1After = IERC20(derivatives[1]).balanceOf(address(this));

    require(
        balance0Before.add(fee0) <= balance0After,
        "Curve/insufficient-token0-returned"
    );
    require(
        balance1Before.add(fee1) <= balance1After,
        "Curve/insufficient-token1-returned"
    );

    // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
    uint256 paid0 = balance0After - balance0Before;
    uint256 paid1 = balance1After - balance1Before;

    IERC20(derivatives[0]).safeTransfer(owner, paid0);
    IERC20(derivatives[1]).safeTransfer(owner, paid1);

    emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
}
function emergencyWithdraw(
    uint256 _curvesToBurn,
    uint256 _deadline
)
    external
    isEmergency
    deadline(_deadline)
    nonReentrant
    returns (uint256[] memory withdrawals_)
{
    return
        ProportionalLiquidity.emergencyProportionalWithdraw(
            curve,
            _curvesToBurn
        );
}
