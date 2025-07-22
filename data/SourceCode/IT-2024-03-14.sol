function transfer(address sender, address recipient, uint256 amount) {
    _transfer(sender, recipient, amount);
}

function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(isActivated[sender], "Sender is not activated");

    // rule 1-2
    require(
        address(exchange) == address(0) ||
            recipient == address(exchange) ||
            !isPancakeSwapPool(recipient),
        "Transfer not allowed"
    );

    // rule 5
    require(
        address(exchange) == address(0) ||
            ((isContract(sender) || allowedContracts[sender]) &&
                (!isContract(recipient))),
        "Transfer rule 5 violated"
    );

    // rule 4
    require(
        address(exchange) == address(0) ||
            _totallyUnlockedAddresses[sender] ||
            _totallyUnlockedAddresses[recipient],
        "Transfer rule 4 violated"
    );

    if (!isActivated[recipient]) {
        isActivated[recipient] = true;
    }

    if (_firstBuyRates[recipient] == 0) {
        _firstBuyRates[recipient] = getUsdtRate();
    }

    if (address(exchange) == sender) {
        if (exchange.totalSupply() >= _lastExchangeTotalSupply) {
            updateCurrMaxUsdtRateIfNeeded();
            makeReferralUnlocksIfNeeded(recipient, amount);
            mintToPoolIfNeeded(amount);
            _mint(_owner, amount.div(20));
        }
    }

    if (address(exchange) != address(0)) {
        _lastExchangeTotalSupply = exchange.totalSupply();
    }

    require(
        amount <= availableBalanceOf(sender),
        "BEP20: transfer amount exceeds available balance"
    );
}
