function transfer(address recipient, uint256 amount) external {
    _transfer(msg.sender, recipient, amount);
}

function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    if (limitsInEffect) {
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTx");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount,"Sell transfer amount exceeds the maxTx");
            } else if (!_isExcludedMaxTransactionAmount[to] && (from != presaleAddress)) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }
    }

    bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

    if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
        swapping = true;
        swapBack();
        swapping = false;
    }

    bool takeFee = !swapping;

    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
        takeFee = false;
    }

    uint256 fees = 0;
    if (takeFee) {
        if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
            fees = (amount * sellTotalFees) / 1000;
        } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
            fees = (amount * buyTotalFees) / 1000;
        }

        if (fees > 0) {
            amount = amount - fees;
            unchecked {
                _balances[address(this)] += fees;
            }
            emit Transfer(from, address(this), fees);
        }
    }

    uint256 senderBalance = _balances[from];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = senderBalance - amount;
        _balances[to] += amount;
    }

    emit Transfer(from, to, amount);
}