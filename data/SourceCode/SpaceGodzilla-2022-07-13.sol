function swapAndLiquifyStepv1() public {
    uint256 ethBalance = ETH.balanceOf(address(this));
    uint256 tokenBalance = balanceOf(address(this));
    addLiquidityUsdt(tokenBalance, ethBalance);
}
