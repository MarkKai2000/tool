function startTrading(address _trader, uint256 _borrowAmount, address _swappedToken) public {
    require( msg.sender ==  _trader || msg.sender == AutoStartOperator, "You don't have permission" );
    if(lastStartMID[_swappedToken] != currentMinuteID())
        lastStartMBorrowAmount[_swappedToken] = 0;
    (,, uint256 MinCollateralLimit,,,uint256 DailyLoanInterestRate,,) = ISwapHelper(SwapHelper).TradingInfo( BUSDContract,_swappedToken );
    uint256 _borrowableAmount = getBorrowableAmount(_swappedToken, _trader);
    require( _borrowAmount <= _borrowableAmount, "Over full borrowable amount limit" );
    require( debtors[_trader].collateralAmount >= MinCollateralLimit, "Cannot trade without depositing collateral funds more than MinCollateralLimit" );
    require( debtors[_trader].tradingState == false, "Trading has already started" );

    totalTradingAmount[_swappedToken] += _borrowAmount;
    lastStartMBorrowAmount[_swappedToken] += _borrowAmount;
    IERC20(BUSDContract).safeApprove(SwapHelper, _borrowAmount);
    uint256 swapOutAmount = ISwapHelper(SwapHelper).swaptoToken( BUSDContract,_swappedToken, _borrowAmount);
    debtors[_trader].tradingState = true;
    debtors[_trader].debtAmount = _borrowAmount;
    debtors[_trader].swappedAmount = swapOutAmount;
    debtors[_trader].swappedToken = _swappedToken;
    debtors[_trader].startTime = block.timestamp;
    debtors[_trader].withdrawableAmount = 0;
    addTrader(_trader);

    lastStartMID[_swappedToken] = currentMinuteID();
    unsetAutoStartTrading(_trader);

    // calculate the total profit
    if(tradeInfo[_swappedToken].startstate==false){
        tradeInfo[_swappedToken].startstate = true;
        tradeInfo[_swappedToken].lastTradeTime = block.timestamp;
    }
    tradeInfo[_swappedToken].totalTradeProfit += (tradeInfo[_swappedToken].totalTradeAmount * ( block.timestamp - tradeInfo[_swappedToken].lastTradeTime ) * DailyLoanInterestRate).div(percentRate * rewardPeriod);
    tradeInfo[_swappedToken].totalTradeAmount += _borrowAmount;
    tradeInfo[_swappedToken].lastTradeTime = block.timestamp;

}