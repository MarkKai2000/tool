function splitDAO(
    uint _proposalID,
    address _newCurator
) noEther onlyTokenholders returns (bool _success) {
    Proposal p = proposals[_proposalID];
    // Sanity check

    if (
        now < p.votingDeadline || // has the voting deadline arrived?
        //The request for a split expires XX days after the voting deadline
        now > p.votingDeadline + splitExecutionPeriod ||
        // Does the new Curator address match?
        p.recipient != _newCurator ||
        // Is it a new curator proposal?
        !p.newCurator ||
        // Have you voted for this split?
        !p.votedYes[msg.sender] ||
        // Did you already vote on another proposal?
        (blocked[msg.sender] != _proposalID && blocked[msg.sender] != 0)
    ) {
        throw;
    }

    // If the new DAO doesn't exist yet, create the new DAO and store the
    // current split data
    if (address(p.splitData[0].newDAO) == 0) {
        p.splitData[0].newDAO = createNewDAO(_newCurator);
        // Call depth limit reached, etc.
        if (address(p.splitData[0].newDAO) == 0) throw;
        // should never happen
        if (this.balance < sumOfProposalDeposits) throw;
        p.splitData[0].splitBalance = actualBalance();
        p.splitData[0].rewardToken = rewardToken[address(this)];
        p.splitData[0].totalSupply = totalSupply;
        p.proposalPassed = true;
    }

    // Move ether and assign new Tokens
    /**

     */
    uint fundsToBeMoved = (balances[msg.sender] * p.splitData[0].splitBalance) /
        p.splitData[0].totalSupply;
    if (
        p.splitData[0].newDAO.createTokenProxy.value(fundsToBeMoved)(
            msg.sender
        ) == false
    ) throw;

    uint rewardTokenToBeMoved = (balances[msg.sender] *
        p.splitData[0].rewardToken) / p.splitData[0].totalSupply;

    uint paidOutToBeMoved = (DAOpaidOut[address(this)] * rewardTokenToBeMoved) /
        rewardToken[address(this)];

    rewardToken[address(p.splitData[0].newDAO)] += rewardTokenToBeMoved;
    if (rewardToken[address(this)] < rewardTokenToBeMoved) throw;
    rewardToken[address(this)] -= rewardTokenToBeMoved;

    DAOpaidOut[address(p.splitData[0].newDAO)] += paidOutToBeMoved;
    if (DAOpaidOut[address(this)] < paidOutToBeMoved) throw;
    DAOpaidOut[address(this)] -= paidOutToBeMoved;

    // Burn DAO Tokens
    Transfer(msg.sender, 0, balances[msg.sender]);

    withdrawRewardFor(msg.sender); // be nice, and get his rewards
    totalSupply -= balances[msg.sender];
    balances[msg.sender] = 0;
    paidOut[msg.sender] = 0;
    return true;
}
