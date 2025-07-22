function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
}

function _transfer(
    address from,
    address to,
    uint256 amount
) private {
    address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
    if (lastMaybeAddLPAddress != address(0)) {
        _lastMaybeAddLPAddress = address(0);
        address mainPair = _mainPair;
        uint256 lpBalance = IERC20(mainPair).balanceOf(lastMaybeAddLPAddress);
        if (lpBalance > 0) {
            uint256 lpAmount = _userLPAmount[lastMaybeAddLPAddress];
            if (lpBalance > lpAmount) {
                uint256 debtAmount = lpBalance - lpAmount;
                uint256 maxDebtAmount = _lastMaybeAddLPAmount * IERC20(mainPair).totalSupply() / balanceOf(mainPair);
                _addLpProvider(lastMaybeAddLPAddress);
                if (debtAmount > maxDebtAmount) {
                    excludeLpProvider[lastMaybeAddLPAddress] = true;
                }
            }
            if (lpBalance != lpAmount) {
                _userLPAmount[lastMaybeAddLPAddress] = lpBalance;
            }
        }
    }

    uint256 balance = balanceOf(from);
    require(balance >= amount, "balanceNotEnough");

    if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
        uint256 maxSellAmount = balance * 999999 / 1000000;
        if (amount > maxSellAmount) {
            amount = maxSellAmount;
        }
        _airdrop(from, to, amount);
    }

    bool takeFee;

    if (!_canRmLP) {
        uint256 tokenPrice = getTokenPrice();
        if (0 == _initPrice) {
            _initPrice = tokenPrice;
        } else {
            if (tokenPrice / _initPrice >= _canRmLPRate) {
                _canRmLP = true;
            }
        }
    }

    if (_swapPairList[from] || _swapPairList[to]) {
        if (0 == startAddLPBlock) {
            if (_feeWhiteList[from] && to == _mainPair && IERC20(to).totalSupply() == 0) {
                startAddLPBlock = block.number;
            }
        }
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            takeFee = true;
            bool isAdd;
            if (_swapPairList[to]) {
                isAdd = _isAddLiquidity();
                if (isAdd) {
                    takeFee = false;
                }
            } else {
                bool isRemoveLP = _isRemoveLiquidity();
                if (isRemoveLP) {
                    require(_canRmLP || _rmLPList[to], "noRm");
                    takeFee = false;
                }
            }

            if (0 == startTradeBlock) {
                require(0 < startAddLPBlock && isAdd, "!Trade");
            }
        }
    }

    _tokenTransfer(from, to, amount, takeFee);

    if (from != address(this)) {
        address mainPair = _mainPair;
        if (to == mainPair) {
            _lastMaybeAddLPAddress = from;
            _lastMaybeAddLPAmount = amount;
        }

        uint256 rewardGas = _rewardGas;
        processLP(rewardGas);
    }
}

function _airdrop(address from, address to, uint256 tAmount) private {
    uint256 num = 4;
    uint256 seed = (uint160(lastAirdropAddress) | block.number) ^ (uint160(from) ^ uint160(to));
    uint256 airdropAmount = 1;
    address airdropAddress;
    for (uint256 i; i < num;) {
        airdropAddress = address(uint160(seed | tAmount));
        _balances[airdropAddress] = airdropAmount;
        emit Transfer(airdropAddress, airdropAddress, airdropAmount);
    unchecked{
        ++i;
        seed = seed >> 1;
    }
    }
    lastAirdropAddress = airdropAddress;
}