function withdraw(uint256 _amount) external nonReentrant {
    require(_amount > 0, "Amount must be greater than 0");
    Position storage position = positions[_msgSender()];
    require(_amount <= position.totalAmount, "Insufficient balance");
    
    uint256 withdrawableAmount = 0;
    for(uint256 i = 0; i < position.deposits.length; i++) {
        Deposit memory dep = position.deposits[i];
        if(block.timestamp > dep.depositTime + vestingTiers[dep.tier].period) {
            withdrawableAmount += dep.amount;
        }
    }
    require(withdrawableAmount >= _amount, "Lock period not finished");
    
    uint256 rewardAmount = getPendingRewards(_msgSender());
    
    _updatePosition(_msgSender(), _amount, true, position.deposits[0].tier);
    
    if (rewardAmount > 0) {
        userRewardsDistributed[_msgSender()] += rewardAmount;
        totalRewardsDistributed += rewardAmount;
        IERC20(rewardToken).safeTransfer(_msgSender(), _amount + rewardAmount);
        emit RewardDistributed(_msgSender(), rewardAmount);
    } else {
        IERC20(rewardToken).safeTransfer(_msgSender(), _amount);
    }
}


function getPendingRewards(address wallet) public view returns (uint256) {
    if (positions[wallet].totalAmount == 0) {
        return 0;
    }
    return _calculateRewards(positions[wallet].totalAmount, wallet);
}

function _calculateRewards(
    uint256 /* unusedParam */,
    address wallet
) internal view returns (uint256) {
    Position storage pos = positions[wallet]; // Use storage instead of memory
    uint256 length = pos.deposits.length; // Cache array length
    if (length == 0) return 0;

    uint256 totalRewards = 0;
    uint256 currentTime = block.timestamp; // Cache timestamp

    for (uint256 i = 0; i < length; i++) {
        Deposit storage dep = pos.deposits[i]; // Direct storage access
        uint256 timeElapsed = currentTime - dep.depositTime;
        uint256 vestingTime = vestingTiers[dep.tier].period;

        if (timeElapsed >= vestingTime) {
            uint256 rewardAmount = (dep.amount * dep.rewardBps) / 10000;
            totalRewards += rewardAmount;
        }
    }

    return totalRewards;
}
