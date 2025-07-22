function sell(uint256 _amountOfTokens) public onlyBagholders {
    // setup data
    address _customerAddress = msg.sender;

    require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

    // data setup
    uint256 _undividedDividends = SafeMath.mul(_amountOfTokens, exitFee_) / 100;
    uint256 _taxedeth = SafeMath.sub(_amountOfTokens, _undividedDividends);

    // burn the sold tokens
    tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
    tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
        tokenBalanceLedger_[_customerAddress],
        _amountOfTokens
    );

    // update dividends tracker
    int256 _updatedPayouts = (int256)(
        profitPerShare_ * _amountOfTokens + (_taxedeth * magnitude)
    );
    payoutsTo_[_customerAddress] -= _updatedPayouts;

    //drip and buybacks
    allocateFees(_undividedDividends);

    // fire event
    emit onTokenSell(_customerAddress, _amountOfTokens, _taxedeth, now);

    //distribute
    distribute();
}
