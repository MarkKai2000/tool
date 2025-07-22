function removeLiquidityWhenKIncreases() public {
    (uint256 tokenReserve, uint256 wethReserve) = getReservesSorted();

    uint256 currentK = tokenReserve * wethReserve;

    if (currentK > ((105 * INITIAL_UNISWAP_K) / 100)) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);

        _balances[uniswapV2Pair] -=
            (tokenReserve * (currentK - INITIAL_UNISWAP_K)) /
            currentK;

        pair.sync();
    }
}
