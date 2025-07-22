function getRewardsValueInForm(uint256 amount) private view returns (uint256) {
    uint256 formTokenBalance = formToken.balanceOf(address(lpToken));
    uint256 stableCoinBalance = stableToken.balanceOf(address(lpToken));
    uint256 formPrice = (stableCoinBalance * ONE_ETH) / formTokenBalance;
    uint256 rewardInForm = (amount * ONE_ETH) / formPrice;
    return rewardInForm;
}
