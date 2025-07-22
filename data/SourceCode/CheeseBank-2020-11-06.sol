function fetchLPAnchorPrice(
    string memory symbol,
    TokenConfig memory config,
    uint ethPrice
) internal virtual returns (uint) {
    //only support ETH pair
    ERC20 wETH = ERC20(getTokenConfigBySymbolHash(ethHash).underlying);
    uint wEthBalance = wETH.balanceOf(config.uniSwapMarket);
    uint pairBalance = mul(wEthBalance, 2);
    uint totalValue = mul(pairBalance, ethPrice);

    IUniswapV2Pair pair = IUniswapV2Pair(config.uniSwapMarket);
    uint anchorPrice = totalValue / pair.totalSupply();

    return anchorPrice;
}
