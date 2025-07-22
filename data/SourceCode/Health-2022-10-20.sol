function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
}
function _transfer(address from, address to, uint256 value) private {
    require(value <= _balances[from]);
    require(to != address(0));

    uint256 contractTokenBalance = balanceOf(address(this));

    bool overMinTokenBalance = contractTokenBalance >=
        numTokensSellToAddToLiquidity;
    if (
        overMinTokenBalance &&
        !inSwapAndLiquify &&
        to == uniswapV2Pair &&
        swapAndLiquifyEnabled
    ) {
        contractTokenBalance = numTokensSellToAddToLiquidity;
        //add liquidity
        swapAndLiquify(contractTokenBalance);
    }
    if (block.timestamp >= pairStartTime.add(jgTime) && pairStartTime != 0) {
        if (from != uniswapV2Pair) {
            uint256 burnValue = _balances[uniswapV2Pair].mul(burnFee).div(1000);
            _balances[uniswapV2Pair] = _balances[uniswapV2Pair].sub(burnValue);
            _balances[_burnAddress] = _balances[_burnAddress].add(burnValue);
            if (block.timestamp >= pairStartTime.add(jgTime)) {
                pairStartTime += jgTime;
            }
            emit Transfer(uniswapV2Pair, _burnAddress, burnValue);
            IPancakePair(uniswapV2Pair).sync();
        }
    }
    uint256 devValue = value.mul(devFee).div(1000);
    uint256 bValue = value.mul(bFee).div(1000);
    uint256 newValue = value.sub(devValue).sub(bValue);
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(newValue);
    _balances[address(this)] = _balances[address(this)].add(devValue);
    _balances[_burnAddress] = _balances[_burnAddress].add(bValue);

    emit Transfer(from, to, newValue);
    emit Transfer(from, address(this), devValue);
    emit Transfer(from, _burnAddress, bValue);
}
