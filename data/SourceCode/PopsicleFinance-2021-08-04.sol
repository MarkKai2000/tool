/**
 * @notice Used to withdraw accumulated user's fees.
 */
function collectFees(uint256 amount0, uint256 amount1) external nonReentrant {
    updateVault(msg.sender);
    UserInfo storage user = userInfo[msg.sender];
    require(user.token0Rewards >= amount0, "AOR");
    require(user.token1Rewards >= amount1, "AIR");
    uint256 balance0 = _balance0();
    uint256 balance1 = _balance1();
    if (balance0 >= amount0 && balance1 >= amount1) {
        if (amount0 > 0) pay(token0, address(this), msg.sender, amount0);
        if (amount1 > 0) pay(token1, address(this), msg.sender, amount1);
    } else {
        uint128 liquidity = pool.liquidityForAmounts(
            amount0,
            amount1,
            tickLower,
            tickUpper
        );
        (amount0, amount1) = pool.burnExactLiquidity(
            tickLower,
            tickUpper,
            liquidity,
            msg.sender
        );
    }
    user.token0Rewards = user.token0Rewards.sub(amount0);
    user.token1Rewards = user.token1Rewards.sub(amount1);
    emit RewardPaid(msg.sender, amount0, amount1);
}

// Function modifier that calls update fees reward function
modifier updateVault(address account) {
    _updateFeesReward(account);
    _;
}

// Updates user's fees reward
function _updateFeesReward(address account) internal {
    uint256 liquidity = pool.positionalLiquidity(tickLower, tickUpper);
    if (liquidity == 0) return; // we can't poke when liquidity is zero
    (uint256 collect0, uint256 collect1) = _earnFees();

    token0PerShareStored = _tokenPerShare(collect0, token0PerShareStored);
    token1PerShareStored = _tokenPerShare(collect1, token1PerShareStored);

    if (account != address(0)) {
        UserInfo storage user = userInfo[msg.sender];
        user.token0Rewards = _feeEarned(account, token0PerShareStored);
        user.token0PerSharePaid = token0PerShareStored;

        user.token1Rewards = _feeEarned(account, token1PerShareStored);
        user.token1PerSharePaid = token1PerShareStored;
    }
}

// Calculates how much token0 is entitled for a particular user.
function _fee0Earned(address account, uint256 fee0PerShare_)
    internal
    view
    returns (uint256)
{
    UserInfo memory user = userInfo[account];
    return
        balanceOf(account)
            .mul(fee0PerShare_.sub(user.token0PerSharePaid))
            .unsafeDiv(1e18)
            .add(user.token0Rewards);
}

// Calculates how much token1 is entitled for a particular user.
function _fee1Earned(address account, uint256 fee1PerShare_)
    internal
    view
    returns (uint256)
{
    UserInfo memory user = userInfo[account];
    return
        balanceOf(account)
            .mul(fee1PerShare_.sub(user.token1PerSharePaid))
            .unsafeDiv(1e18)
            .add(user.token1Rewards);
}
