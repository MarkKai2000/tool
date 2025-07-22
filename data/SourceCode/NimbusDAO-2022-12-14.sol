function getReward() public override nonReentrant whenNotPaused {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
        for (uint256 i = 0; i < stakeNonces[msg.sender]; i++) {
            stakeNonceInfos[msg.sender][i].stakeTime = block.timestamp;
        }
        rewardsPaymentToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, address(rewardsPaymentToken), reward);
    }
}
