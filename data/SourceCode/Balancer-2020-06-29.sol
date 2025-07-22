function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    // 代币通缩逻辑
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    // 进行代币通缩
    _totalSupply = _totalSupply.sub(tokensToBurn);
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
}

function swapExactAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    address tokenOut,
    uint minAmountOut,
    uint maxPrice
) external _logs_ _lock_ returns (uint tokenAmountOut, uint spotPriceAfter) {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");
    // 获取兑换时转入代币和要转出的代币的余额
    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];
    require(
        tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO),
        "ERR_MAX_IN_RATIO"
    );
    uint spotPriceBefore = calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
    );
    require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");
    // 计算兑换代币的数额
    tokenAmountOut = calcOutGivenIn(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        tokenAmountIn,
        _swapFee
    );
    require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
    // 更新转入和转出代币的余额
    inRecord.balance = badd(inRecord.balance, tokenAmountIn);
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);
    spotPriceAfter = calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
    );
    require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
    require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
    require(
        spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
        "ERR_MATH_APPROX"
    );
    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);
    // 拉取用户用于兑换的代币和将用户要兑换的代币推送给用户
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    return (tokenAmountOut, spotPriceAfter);
}

function gulp(address token) external _logs_ _lock_ {
    require(_records[token].bound, "ERR_NOT_BOUND");
    _records[token].balance = IERC20(token).balanceOf(address(this));
}
