/**
 * Sells SURGE Tokens And Deposits the BNB into Seller's Address */
function sell(uint256 tokenAmount) public nonReentrant returns (bool) {
    address seller = msg.sender;

    // make sure seller has this balance
    require(_balances[seller] >= tokenAmount, "cannot sell above token amount");

    // calculate the sell fee from this transaction
    uint256 tokensToSwap = tokenAmount.mul(sellFee).div(10 ** 2);

    // how much BNB are these tokens worth?
    uint256 amountBNB = tokensToSwap.mul(calculatePrice());

    // send BNB to Seller
    (bool successful, ) = payable(seller).call{value: amountBNB, gas: 40000}(
        ""
    );
    if (successful) {
        // subtract full amount from sender
        _balances[seller] = _balances[seller].sub(
            tokenAmount,
            "sender does not have this amount to sell"
        );

        // if successful, remove tokens from supply
        _totalSupply = _totalSupply.sub(tokenAmount);
    } else {
        revert();
    }

    emit Transfer(seller, address(this), tokenAmount);
    return true;
}

/**
 * Purchases SURGE Tokens and Deposits Them in Sender's Address
 */
function purchase(address buyer, uint256 bnbAmount) internal returns (bool) {
    // make sure we don't buy more than the bnb in this contract
    require(
        bnbAmount <= address(this).balance,
        "purchase not included in balance"
    );

    // previous amount of BNB before we received any
    uint256 prevBNBAmount = (address(this).balance).sub(bnbAmount);

    // if this is the first purchase, use current balance
    prevBNBAmount = prevBNBAmount == 0 ? address(this).balance : prevBNBAmount;

    // find the number of tokens we should mint to keep up with the current price
    uint256 nShouldPurchase = hyperInflatePrice
        ? _totalSupply.mul(bnbAmount).div(address(this).balance)
        : _totalSupply.mul(bnbAmount).div(prevBNBAmount);

    // apply our spread to tokens to inflate price relative to total supply
    uint256 tokensToSend = nShouldPurchase.mul(spreadDivisor).div(10 ** 2);

    // revert if under 1
    if (tokensToSend < 1) {
        revert("Must Buy More Than One Surge");
    }

    // mint the tokens we need to the buyer
    mint(buyer, tokensToSend);
    emit Transfer(address(this), buyer, tokensToSend);
    return true;
}
