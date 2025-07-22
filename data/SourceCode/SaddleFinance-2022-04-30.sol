// https://github.com/saddle-finance/saddle-contract/blob/141a00e7ba0c5e8d51d8018d3c4a170e63c6c7c4/contracts/meta/MetaSwapUtils.sol#L424
function _calculateSwap(
    SwapUtils.Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 baseVirtualPrice
) internal view returns (uint256 dy, uint256 dyFee) {
    uint256[] memory xp = _xp(self, baseVirtualPrice);
    require(
        tokenIndexFrom < xp.length && tokenIndexTo < xp.length,
        "Token index out of range"
    );
    uint256 x = dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom]).add(
        xp[tokenIndexFrom]
    );
    uint256 y = SwapUtils.getY(
        self._getAPrecise(),
        tokenIndexFrom,
        tokenIndexTo,
        x,
        xp
    );
    dy = xp[tokenIndexTo].sub(y).sub(1);
    dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
    dy = dy.sub(dyFee).div(self.tokenPrecisionMultipliers[tokenIndexTo]);
}
