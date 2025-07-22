function _withdraw(
    uint256 amount,
    address user,
    address recipient
) internal nonReentrant updateReward(user) {
    require(amount != 0, "Cannot withdraw 0");

    // not using safe math, because there is no way to overflow if stake tokens not overflow
    totalSupply = totalSupply - amount;
    _balances[user] = _balances[user] - amount;

    // not using safe transfer, because we working with trusted tokens
    require(stakingToken.transfer(recipient, amount), "token transfer failed");

    emit Withdrawn(user, amount);
}
