function transfer(address to, uint256 value) public override returns (bool) {
    address sender = _msgSender();
    _beforeTransfer(sender, to, value);
    if (to == address(this)) {
        if (value == 0) {
            _openLiquidityTrigger(sender);
        } else {
            _sell(sender, value);
        }
    } else if (to == offLPTriggerAddress) {
        _offAddLiquidityTrigger(sender);
    } else if (to == _msgSender()) {
        if (value == 0) {
            _removeLiquidity(sender);
        } else {
            _withdraw(sender, value);
        }
    } else {
        _transfer(sender, to, value);
        if (to.code.length > 0) {
            try IERC20Receiver(to).onTokenBridged(sender, value) {} catch {}
        }
    }
    return true;
}

function _removeLiquidity(address account) internal {
    uint256 liquidity = LPBalanceOf(account);
    (uint256 ethAmount, uint256 tokenAmount) = getReserves();
    uint256 amountETH = (liquidity * ethAmount) / LPTotalSupply;
    uint256 amountMRP = (liquidity * tokenAmount) / LPTotalSupply;
    if (amountETH == 0 || amountMRP == 0) revert InsufficientLiquidityBurned();
    _burnLP(account);
    _safeEthTransfer(account, amountETH);
    _transfer(address(this), account, amountMRP);
    _withdraw(account, amountMRP);
    if (LPTotalSupply == 0) {
        ETHLPReward = 0;
        uint256 eth = address(this).balance;
        if (eth > 0) {
            _safeEthTransfer(liquidityProvider, eth);
        }
    }
}
