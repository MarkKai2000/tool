function emergencyWithdraw(uint256 _pid) external {
    require(_pid < poolInfo.length, "updatePool: invalid _pid");

    PoolInfo storage pool = poolInfo[_pid];

    // here is your user from the pool
    UserInfo storage user = userInfo[_pid][msg.sender];

    // this is the amount that you have in your pool
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    // this function does the transfer of your staked tokens to your account
    pool.tokenContract.safeTransfer(address(msg.sender), amount);

    emit EmergencyWithdraw(msg.sender, _pid, amount);
}
