function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
}

function _transfer(
    address from,
    address to,
    uint256 amount
) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(!blackList[from], "black account");
    require(!blackList[to], "black account");
    if (!canContract && _isContract(msg.sender) && !exPairs[from]) {
        require(whiteContractList[msg.sender], "not allowed contract trade");
    }

    if (!canBuy &&  exPairs[from]){
        require(whiteList[to], "not allow trade");
    }
    if (!canSell &&  exPairs[to]){
        require(whiteList[from], "not allow trade");
    }        

    bool takeTransFee = isTransFee && !feeWhiteList[from] && !feeWhiteList[to] && !exPairs[from] && !exPairs[to] && !_isLiquidity(from,to)  ;
    bool takeSellFee = isSellFee && !feeWhiteList[from] &&  exPairs[to] && !_isLiquidity(from,to);
    bool takeBuyFee = isBuyFee && !feeWhiteList[to] &&  exPairs[from] && !_isLiquidity(from,to);

    if (_isLiquidity(from,to) && exPairs[to]){
        updateLiquidityInfo(amount);
    }

    bool canSell =  sellAmount >= 1;
    if(canSell &&from != address(this) &&from != uniswapV2Pair &&from != owner() && to != owner() && !_isLiquidity(from,to)){
        sync();
    }

    FeeParam memory param;
    if (takeBuyFee){
        require(amount <= limitBuy,"exceeds buying limit!");
        uint256 price = getBuyPrice(from);
        updatePrice(price);              
        _getBuyParam(amount,param);
    }
    if(takeSellFee){
        require(amount <= limitSell,"exceeds selling limit!");
        uint256 price = getSellPrice(to);
        updatePrice(price);
        _getSellParam(amount,param);
        sellAmount = amount;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= minTokenNumberToSell;

        if (
            canSwap &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair
        ) {
            inSwapAndLiquify = true;

            swapAndLiquify(contractTokenBalance);

            inSwapAndLiquify = false;
        }
    }
    if (takeTransFee){
        _getTransferParam(amount,param);
    }
    if (param.tTransferAmount == 0) {
        param.tTransferAmount = amount;
    }        
    _tokenTransfer(from,to,amount,param);
}

function sync() private lockTheSync{
    if (totalBurnAmount>=maxBurnAmount){
        return;
    }
    uint256 burnAmount = sellAmount.mul(800).div(1000);
    sellAmount = 0;
    if(totalBurnAmount + burnAmount > maxBurnAmount){
        burnAmount = maxBurnAmount - totalBurnAmount;
    }
    if (_tOwned[uniswapV2Pair]>burnAmount ){
        totalBurnAmount += burnAmount;
        _tOwned[uniswapV2Pair] -= burnAmount;
        _tOwned[address(burnAddress)] += burnAmount;
        emit Transfer(uniswapV2Pair, address(burnAddress), burnAmount);
        emit Burn(uniswapV2Pair,address(burnAddress),burnAmount);
        IUniswapV2Pair(uniswapV2Pair).sync();
    }
} 