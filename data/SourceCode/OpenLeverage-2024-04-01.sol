function payoffTrade(
    uint16 marketId,
    bool longToken
) external payable override nonReentrant {
    Types.Trade storage trade = activeTrades[msg.sender][marketId][longToken];
    bool depositToken = trade.depositToken;
    uint deposited = trade.deposited;
    Types.MarketVars memory marketVars = OpenLevV1Lib.toMarketVar(
        longToken,
        false,
        markets[marketId]
    );

    //verify

    require(trade.held != 0 && trade.lastBlockNum != block.number, "HI0");

    (ControllerInterface(addressConfig.controller)).closeTradeAllowed(marketId);

    uint heldAmount = trade.held;

    uint closeAmount = OpenLevV1Lib.shareToAmount(
        heldAmount,
        totalHelds[address(marketVars.sellToken)],
        marketVars.reserveSellToken
    );

    uint borrowed = OpenLevV1Lib.borrowCurrent(marketVars.buyPool, msg.sender);

    //first transfer token to OpenLeve, then repay to pool, two transactions with two tax deductions

    uint24 taxRate = taxes[marketId][address(marketVars.buyToken)][0];

    uint firstAmount = Utils.toAmountBeforeTax(borrowed, taxRate);

    uint transferAmount = transferIn(
        msg.sender,
        marketVars.buyToken,
        Utils.toAmountBeforeTax(firstAmount, taxRate),
        true
    );

    OpenLevV1Lib.repay(marketVars.buyPool, msg.sender, transferAmount);

    require(marketVars.buyPool.borrowBalanceStored(msg.sender) == 0, "IRP");

    delete activeTrades[msg.sender][marketId][longToken];

    totalHelds[address(marketVars.sellToken)] = totalHelds[
        address(marketVars.sellToken)
    ].sub(heldAmount);

    doTransferOut(msg.sender, marketVars.sellToken, closeAmount);

    emit TradeClosed(
        msg.sender,
        marketId,
        longToken,
        depositToken,
        heldAmount,
        deposited,
        heldAmount,
        0,
        0,
        0
    );
}
