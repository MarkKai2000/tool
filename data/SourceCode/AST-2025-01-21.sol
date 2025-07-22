function transfer(
    address to,
    uint256 amount
) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
}

function transferFrom(
    address from,
    address to,
    uint256 amount
) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
}

function _transfer(address from, address to, uint256 amount) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
    if (fromBalance == amount && fromBalance >= 1e14) {
        amount -= 1e14;
    }

    if (
        from != uniswapV2Pair &&
        !wList[from] &&
        !wList[to] &&
        to != uniswapV2Pair
    ) {
        _balances[to] += (amount);
        emit Transfer(from, to, (amount));
    } else if (wList[from] || wList[to]) {
        // wList 中的地址进行交易，不收取手续费
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    } else {
        uint feeAmount;
        if (to == uniswapV2Pair) {
            if (!checkLiquidityAdd(from)) {
                if (saleFeeRate > 0) {
                    feeAmount = (amount * saleFeeRate) / 100;
                    _balances[sellfee] += feeAmount;
                    emit Transfer(from, sellfee, feeAmount);
                }
            }
        }
        if (from == uniswapV2Pair) {
            if (checkLiquidityRm(to)) {
                // 如果移除流动性，则销毁代币
                _burn(from, amount);
                amount = 0;
            } else {
                if (buyFeeRate > 0) {
                    feeAmount = (amount * buyFeeRate) / 100;
                    _balances[buyfee] += feeAmount;
                    emit Transfer(from, buyfee, feeAmount);
                }
            }
        }
        _balances[to] += (amount - feeAmount);
        emit Transfer(from, to, (amount - feeAmount));
    }
    _afterTokenTransfer(from, to, amount);
}
