function mint(address _address, uint256 _amount) external onlyMint {
    require(_amount > 0, "must be greater than 0");
    uint256 _bal = this.balanceOf(address(0xdead));
    require(_bal >= _amount, "The black hole address balance is insufficient");
    super._transfer(address(0xdead), _address, _amount);
}

function _transfer(
    address from,
    address recipient,
    uint256 amount
) internal override {
    if (block.timestamp >= lastBurnTime + lastBurnGapTime) {
        uint256 totalNum = this.balanceOf(liquidityPool);
        uint256 burnNum = (totalNum * burnRate) / 10000;
        super._transfer(liquidityPool, address(0xdead), burnNum);
        IPancakePair(liquidityPool).sync();
    }

    if (isExcludedFromFee[from] || isExcludedFromFee[recipient]) {
        super._transfer(from, recipient, amount);
        return;
    }

    if (from == liquidityPool) {
        uint256 taxAmount = (amount * buyorsellTax) / 10000; // 滑点总数
        uint256 amountAfterTax = amount - taxAmount;

        uint256 tax1 = (taxAmount * 20) / 30; // 20% 给社区钱包
        uint256 tax2 = (taxAmount * 10) / 30; // 10% 拉盘AAX

        super._transfer(from, buyorsellTaxWallet, tax1);
        super._transfer(from, dividendAddress, tax2);
        super._transfer(from, recipient, amountAfterTax);
        return;
    }
}
