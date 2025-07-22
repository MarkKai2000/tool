function claimMultiple(uint256[] calldata _epoches, address _to) external {
  uint256 totalReward;
  for (uint256 i = 0; i < _epoches.length; ++i) {
    uint256 epoch = _epoches[i];
    if (epoch < currentEpoch) {
      uint256 reward = claimable(epoch, msg.sender);
      if (reward > 0) {
        users[epoch][msg.sender].claimed = reward;
        totalReward += reward;
        emit Claimed(epoch, _to, reward);
      }
    }
  }

  LVL.safeTransfer(_to, totalReward);
}

function claimable(uint256 _epoch, address _user) public view returns (uint256) {
    EpochInfo memory epoch = epochs[_epoch];

    if (epoch.TWAP == 0) {
        return 0;
    }

    UserInfo memory user = users[_epoch][_user];
    address referrer = referralRegistry.referredBy(_user);

    uint256 rewardForTrading = user.tradingPoint * tiers[users[_epoch][referrer].tier].discountForTrader / PRECISION;
    uint256 rewardForReferral = user.referralPoint * tiers[user.tier].rebateForReferrer / PRECISION;
    uint256 reward = (rewardForTrading + rewardForReferral) / epoch.TWAP;
    if (epoch.vestingDuration != 0) {
        uint256 duration = block.timestamp >= (epoch.allocationTime + epoch.vestingDuration)
            ? epoch.vestingDuration
            : (block.timestamp - epoch.allocationTime);
        reward = reward * duration / epoch.vestingDuration;
    }

    return reward > user.claimed ? reward - user.claimed : 0;
}