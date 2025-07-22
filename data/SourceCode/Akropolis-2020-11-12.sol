function deposit(
    address _protocol,
    address[] memory _tokens,
    uint256[] memory _dnAmounts
) public operationAllowed(IAModule.Operation.Deposit) returns (uint256) {
    // distributeRewardIfRequired(_protocol);

    uint256 nAmount;
    for (uint256 i = 0; i < _tokens.length; i++) {
        nAmount = nAmount.add(normalizeTokenAmount(_tokens[i], _dnAmounts[i]));
    }

    uint256 nBalanceBefore = distributeYieldInternal(_protocol); //1. Check before balance
    depositToProtocol(_protocol, _tokens, _dnAmounts); //2. Add liquidity to protocol
    uint256 nBalanceAfter = updateProtocolBalance(_protocol); //3. check afterBalance

    PoolToken poolToken = PoolToken(protocol[_protocol].poolToken);
    uint256 nDeposit = nBalanceAfter.sub(nBalanceBefore);

    uint256 cap;
    if (userCapEnabled) {
        cap = userCap(_protocol, msgSender());
    }

    uint256 fee;
    if (nAmount > nDeposit) {
        fee = nAmount - nDeposit;
        poolToken.mint(msgSender(), nDeposit);
    } else {
        fee = 0;
        poolToken.mint(msgSender(), nAmount);

        uint256 yield = nDeposit - nAmount;
        if (yield > 0) {
            // Additional yield received from protocol (because of lottery, or something)
            createYieldDistribution(poolToken, yield);
        }
    }
}
