function getPrice(address underlying) internal view returns (uint) {
    if (prices[underlying] != 0) {
        // return v1 price.
        return prices[address(underlying)];
    } else if (underlying == FTS_ADDRESS) {
        // Handle Umbrella supported tokens.
        return getUmbrellaPrice(ftsKey);
    } else if (areLPs[underlying]) {
        // Handle LP tokens.
        return getLPFairPrice(underlying);
    } else {
        // Handle Chainlink supported tokens.
        return getChainlinkPrice(getFeed(underlying));
    }
}
