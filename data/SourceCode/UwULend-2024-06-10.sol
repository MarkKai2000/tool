interface IPriceGetter {
    function getPrice() external view returns (uint256 price);
}
function getAssetPrice(address asset) external view returns (uint256) {
    require(address(assetToPriceGetter[asset]) != address(0), "!exists");
    return assetToPriceGetter[asset].getPrice();
}
function getPrice() external view override returns (uint256) {
    (uint256[] memory prices, bool uniFail) = _getPrices(true);
    uint256 median = uniFail ? (prices[5] + prices[6]) / 2 : prices[5];
    require(median > 0, "Median is zero");
    return FullMath.mulDiv(median, sUSDScalingFactor, 1e3);
}
function _getPrices(
    bool sorted
) internal view returns (uint256[] memory, bool uniFail) {
    uint256[11] memory prices;
    (prices[0], prices[1]) = _getUSDeFraxEMAInUSD();
    (prices[2], prices[3]) = _getUSDeUsdEMAInUSD();
    (prices[4], prices[5]) = _getUSDeDaiEMAInUSD();
    (prices[6], prices[7]) = _getCrvUsdUSDeEMAInUSD();
    (prices[8], prices[9]) = _getUSDeGhoEMAInUSD();
    try UNI_V3_TWAP_USDT_ORACLE.getPrice() returns (uint256 price) {
        prices[10] = price;
    } catch {
        uniFail = true;
    }
    if (sorted) {
        _bubbleSort(prices);
    }
    return (prices, uniFail);
}
