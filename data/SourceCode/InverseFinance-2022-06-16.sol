function latestAnswer() public view returns (uint256) {
    uint256 crvPoolBtcVal = WBTC.balanceOf(address(CRV3CRYPTO)) *
        uint256(BTCFeed.latestAnswer()) *
        1e2;
    uint256 crvPoolWethVal = (WETH.balanceOf(address(CRV3CRYPTO)) *
        uint256(ETHFeed.latestAnswer())) / 1e8;
    uint256 crvPoolUsdtVal = USDT.balanceOf(address(CRV3CRYPTO)) *
        uint256(USDTFeed.latestAnswer()) *
        1e4;

    uint256 crvLPTokenPrice = ((crvPoolBtcVal +
        crvPoolWethVal +
        crvPoolUsdtVal) * 1e18) / crv3CryptoLPToken.totalSupply();

    return (crvLPTokenPrice * vault.pricePerShare()) / 1e18;
}
