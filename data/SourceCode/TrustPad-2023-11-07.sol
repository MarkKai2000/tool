function receiveUpPool(address account, uint256 amount) external {
    require(account != address(0), 'Must specify valid account');
    require(amount > 0, 'Must specify non-zero amount');

    UserInfo storage user = userInfo[account];

    // Re-lock (using old date if already locked)
    // With lock start == block.timestamp, rewardDebt will be reset to 0 - marking the new locking period rewards countup.
    uint256 newLockStartTime;
    if (isLocked(account)) {
        newLockStartTime = depositLockStart[account];
    } else {
        newLockStartTime = LaunchpadLockableStaking(msg.sender).isLocked(account)
            ? LaunchpadLockableStaking(msg.sender).depositLockStart(account)
            : block.timestamp;
    }
    updateDepositLockStart(account, newLockStartTime);
    emit Locked(account, amount, lockPeriod, 0);

    // Transfer deposit
    liquidityMining.stakingToken.safeTransferFrom(msg.sender, address(this), amount);

    stakersCount += user.lastStakedAt > 0 ? 0 : 1;
    user.amount += amount;
    user.lastStakedAt = block.timestamp;
    lastClaimedAt[account] = block.timestamp;

    emit Deposit(account, amount, 0);

    if (address(secondaryStaking) != address(0)) {
        secondaryStaking.deposit(amount);
    }
}


function stakePendingRewards() external notMigrated {
address account = msg.sender;
UserInfo storage user = userInfo[account];
//        require(isRewardMatured(account), 'Rewards are not matured yet');

updateUserPending(account);
uint256 amount = user.pendingRewards;
user.pendingRewards = 0;
user.amount += amount;

if (!isLocked(account)) {
    depositLockStart[account] = block.timestamp;
    user.rewardDebt = 0;
    emit Locked(account, amount, lockPeriod, 0);
}

updateUserDebt(account);

if (address(secondaryStaking) != address(0)) {
    secondaryStaking.deposit(amount);
}

emit StakedPending(account, amount);
}