function skim(address to) external lock { 
    address _token0 = token0;
    address _token1 = token1;
    _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
    _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
}


function transfer(address recipient, uint amount) public override  returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
}

function _transfer(address sender, address recipient, uint amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");

    bool recipientAllow = ConfigBRA(BRA).isAllow(recipient);
    bool senderAllowSell = ConfigBRA(BRA).isAllowSell(sender);

    uint BuyPer = ConfigBRA(BRA).BuyPer();
    uint SellPer = ConfigBRA(BRA).SellPer();

    address BuyTaxTo_ = address(0);
    address SellTaxTo_ = address(0);

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    uint256 finalAmount = amount;
    uint256 taxAmount = 0;

    if(sender==uniswapV2Pair&&!recipientAllow){
        taxAmount = amount.div(10000).mul(BuyPer);
        BuyTaxTo_ = ConfigBRA(BRA).BuyTaxTo();
    }

    if(recipient==uniswapV2Pair&&!senderAllowSell){
        taxAmount = amount.div(10000).mul(SellPer);
        SellTaxTo_ = ConfigBRA(BRA).SellTaxTo();
    }

    finalAmount = finalAmount - taxAmount;

    if(BuyTaxTo_ != address(0)){
        _balances[BuyTaxTo_] = _balances[BuyTaxTo_].add(taxAmount);
        emit Transfer(sender, BuyTaxTo_, taxAmount);
    }

    if(SellTaxTo_ != address(0)){
        _balances[SellTaxTo_] = _balances[SellTaxTo_].add(taxAmount);
        emit Transfer(sender, SellTaxTo_, taxAmount);
    }
    
    _balances[recipient] = _balances[recipient].add(finalAmount);
    
    if (recipient == address(0) ) {
        totalBurn = totalBurn.add(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burn(sender, address(0), amount);
    }
    emit Transfer(sender, recipient, finalAmount);

}