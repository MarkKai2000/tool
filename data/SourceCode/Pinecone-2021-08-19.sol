function deposit(
    uint256 _wantAmt,
    address _user
) public onlyOwner whenNotPaused returns (uint256) {
    IERC20(stakingToken).safeTransferFrom(
        address(msg.sender),
        address(this),
        _wantAmt
    );

    UserAssetInfo storage user = users[_user];
    user.depositedAt = block.timestamp;
    user.depositAmt = user.depositAmt.add(_wantAmt);

    uint256 sharesAdded = _wantAmt;

    (uint256 wantTotal, , ) = balance();
    if (wantTotal > 0 && sharesTotal > 0) {
        sharesAdded = sharesAdded.mul(sharesTotal).div(wantTotal);
    }

    _farmAlpaca();
    _reawardTokenToBSW();
    _claimBSW();
    _farmBSW();

    sharesTotal = sharesTotal.add(sharesAdded);
    uint256 pending = user.shares.mul(accPerShareOfBSW).div(1e12).sub(
        user.rewardPaid
    );
    user.pending = user.pending.add(pending);
    user.shares = user.shares.add(sharesAdded);
    user.rewardPaid = user.shares.mul(accPerShareOfBSW).div(1e12);

    return sharesAdded;
}
