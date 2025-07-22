function sell(uint256 amount) external {
    eve_token_erc20.transferFrom(msg.sender, address(this), amount);
    (, uint256 r1, ) = inner_pair.getReserves();
    uint256 lpAmount = (amount * inner_pair.totalSupply()) / (2 * r1);
    uniswapV2Router.removeLiquidity(
        address(usdt_token_erc20),
        address(eve_token_erc20),
        lpAmount,
        0,
        0,
        msg.sender,
        block.timestamp
    );
}
