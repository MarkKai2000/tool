/// @dev Converts all incoming eth to tokens for the caller, and passes down the referral addy (if any)
function buyFor(
    address _customerAddress,
    uint buy_amount
) public returns (uint256) {
    require(token.transferFrom(_customerAddress, address(this), buy_amount));
    totalDeposits += buy_amount;
    uint amount = purchaseTokens(_customerAddress, buy_amount);

    emit onLeaderBoard(
        _customerAddress,
        stats[_customerAddress].invested,
        tokenBalanceLedger_[_customerAddress],
        stats[_customerAddress].withdrawn,
        now
    );

    //distribute
    distribute();

    return amount;
}

/// @dev Withdraws all of the callers earnings.
function withdraw() public onlyStronghands {
    // setup data
    address _customerAddress = msg.sender;
    uint256 _dividends = myDividends();

    // update dividend tracker
    payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

    // lambo delivery service
    token.transfer(_customerAddress, _dividends);

    //stats
    stats[_customerAddress].withdrawn = SafeMath.add(
        stats[_customerAddress].withdrawn,
        _dividends
    );
    stats[_customerAddress].xWithdrawn += 1;
    totalTxs += 1;
    totalClaims += _dividends;

    // fire event
    emit onWithdraw(_customerAddress, _dividends, now);

    emit onLeaderBoard(
        _customerAddress,
        stats[_customerAddress].invested,
        tokenBalanceLedger_[_customerAddress],
        stats[_customerAddress].withdrawn,
        now
    );

    //distribute
    distribute();
}

function distribute() private {
    if (now.safeSub(lastBalance_) > balanceInterval) {
        emit onBalance(totalTokenBalance(), now);
        lastBalance_ = now;
    }

    if (
        SafeMath.safeSub(now, lastPayout) > distributionInterval &&
        tokenSupply_ > 0
    ) {
        //A portion of the dividend is paid out according to the rate
        uint256 share = dividendBalance_.mul(payoutRate_).div(100).div(
            24 hours
        );
        //divide the profit by seconds in the day
        uint256 profit = share * now.safeSub(lastPayout);
        //share times the amount of time elapsed
        dividendBalance_ = dividendBalance_.safeSub(profit);

        //Apply divs
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            (profit * magnitude) / tokenSupply_
        );

        lastPayout = now;
    }
}

/// @dev Internal function to actually purchase the tokens.
function purchaseTokens(
    address _customerAddress,
    uint256 _incomingeth
) internal returns (uint256) {
    /* Members */
    if (
        stats[_customerAddress].invested == 0 &&
        stats[_customerAddress].receivedTokens == 0
    ) {
        players += 1;
    }

    totalTxs += 1;

    // data setup
    uint256 _undividedDividends = SafeMath.mul(_incomingeth, entryFee_) / 100;
    uint256 _amountOfTokens = SafeMath.sub(_incomingeth, _undividedDividends);

    // fire event
    emit onTokenPurchase(_customerAddress, _incomingeth, _amountOfTokens, now);

    // yes we know that the safemath function automatically rules out the "greater then" equation.
    require(
        _amountOfTokens > 0 &&
            SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_
    );

    // we can't give people infinite eth
    if (tokenSupply_ > 0) {
        // add tokens to the pool
        tokenSupply_ += _amountOfTokens;
    } else {
        // add tokens to the pool
        tokenSupply_ = _amountOfTokens;
    }

    //drip and buybacks
    allocateFees(_undividedDividends);

    // update circulating supply & the ledger address for the customer
    tokenBalanceLedger_[_customerAddress] = SafeMath.add(
        tokenBalanceLedger_[_customerAddress],
        _amountOfTokens
    );

    // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
    // really i know you think you do but you don't
    int256 _updatedPayouts = (int256)(profitPerShare_ * _amountOfTokens);
    payoutsTo_[_customerAddress] += _updatedPayouts;

    //Stats
    stats[_customerAddress].invested += _incomingeth;
    stats[_customerAddress].xInvested += 1;

    return _amountOfTokens;
}

function totalTokenBalance() public view returns (uint256) {
    return token.balanceOf(address(this));
}

function allocateFees(uint fee) private {
    // 1/5 paid out instantly
    uint256 instant = fee.div(5);

    if (tokenSupply_ > 0) {
        // Apply instant divs
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            (instant * magnitude) / tokenSupply_
        );
    }

    // Add 4/5 to dividend drip pools
    dividendBalance_ += fee.safeSub(instant);
}

/**
 * @dev Retrieve the dividends owned by the caller.
 */
function myDividends() public view returns (uint256) {
    address _customerAddress = msg.sender;
    return dividendsOf(_customerAddress);
}

/// @dev Retrieve the dividend balance of any single address.
function dividendsOf(address _customerAddress) public view returns (uint256) {
    return
        (uint256)(
            (int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) -
                payoutsTo_[_customerAddress]
        ) / magnitude;
}
