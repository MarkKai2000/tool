function withdrawWithoutHedge(
    uint256 trancheID
) external override nonReentrant returns (uint256 amount) {
    address owner = ownerOf(trancheID);
    amount = _withdraw(owner, trancheID);
    emit Withdrawn(owner, trancheID, amount);
}

function _withdraw(
    address owner,
    uint256 trancheID
) internal returns (uint256 amount) {
    Tranche storage t = tranches[trancheID];
    // uint256 lockupPeriod =
    //     t.hedged
    //         ? lockupPeriodForHedgedTranches
    //         : lockupPeriodForUnhedgedTranches;
    // require(t.state == TrancheState.Open);
    require(_isApprovedOrOwner(_msgSender(), trancheID));
    require(
        block.timestamp > t.creationTimestamp + lockupPeriod,
        "Pool Error: The withdrawal is locked up"
    );

    t.state = TrancheState.Closed;
    // if (t.hedged) {
    //     amount = (t.share * hedgedBalance) / hedgedShare;
    //     hedgedShare -= t.share;
    //     hedgedBalance -= amount;
    // } else {
    amount = (t.share * totalBalance) / totalShare;
    totalShare -= t.share;
    totalBalance -= amount;
    // }

    token.safeTransfer(owner, amount);
}
