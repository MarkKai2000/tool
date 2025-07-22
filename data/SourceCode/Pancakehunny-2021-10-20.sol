function _harvest(uint256 rewardAmount) private {
    IBEF20 rewardToken = getRewardToken();

    if (rewardAmount > DUST) {
        emit Harvested(rewardAmount);

        // convert reward (ALPACA or RABBIT) to staking token
        uint256 stakingTokenBefore = _stakingToken.balanceOf(address(this));
        address[] memory path = new address[](3);
        (path[0], path[1], path[2]) = (
            address(rewardToken),
            PANCAKE_ROUTER.WETH(),
            address(_stakingToken)
        );

        rewardToken.safeApprove(address(PANCAKE_ROUTER), 0);
        rewardToken.safeApprove(address(PANCAKE_ROUTER), rewardAmount);

        PANCAKE_ROUTER.swapExactTokensForTokens(
            rewardAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 stakingTokenAmount = _stakingToken.balanceOf(address(this)).sub(
            stakingTokenBefore
        );
        _depositStakingToken(stakingTokenAmount);
    }
}
