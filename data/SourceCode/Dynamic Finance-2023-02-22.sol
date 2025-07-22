function getInterest(address _staker) public view returns (uint256) {
    StakeDetail memory stakeDetail = stakers[_staker];
    uint256 duration = block.timestamp.sub(stakeDetail.lastProcessAt);
    uint256 interest = stakeDetail
        .principal
        .mul(apr)
        .mul(duration)
        .div(ONE_YEAR_IN_SECONDS)
        .div(RATE_PRECISION);
    return interest.add(stakeDetail.pendingReward);
}

function deposit(uint256 _stakeAmount) external {
    require(enabled, "Staking is not enabled");
    require(
        _stakeAmount > 0,
        "StakingDYNA: stake amount must be greater than 0"
    );
    token.transferFrom(msg.sender, address(this), _stakeAmount);
    StakeDetail storage stakeDetail = stakers[msg.sender];
    if (stakeDetail.firstStakeAt == 0) {
        stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
        stakeDetail.firstStakeAt = stakeDetail.firstStakeAt == 0
            ? block.timestamp
            : stakeDetail.firstStakeAt;
        stakeDetail.lastProcessAt = block.timestamp;
    } else {
        stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
    }

    emit Deposit(msg.sender, _stakeAmount);
}