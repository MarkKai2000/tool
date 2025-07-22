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
    uint256 y = getY(getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
    dy = xp[tokenIndexTo].sub(y).sub(1);
    dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
    dy = dy.sub(dyFee).div(self.tokenPrecisionMultipliers[tokenIndexTo]);
}

function calculateSwapUnderlying(
    SwapUtils.Swap storage self,
    MetaSwap storage metaSwapStorage,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
) external view returns (uint256) {
    CalculateSwapUnderlyingInfo memory v = CalculateSwapUnderlyingInfo(
        _getBaseVirtualPrice(metaSwapStorage),
        metaSwapStorage.baseSwap,
        0,
        uint8(metaSwapStorage.baseTokens.length),
        0,
        0,
        0
    );

    uint256[] memory xp = _xp(self, v.baseVirtualPrice);
    v.baseLPTokenIndex = uint8(xp.length) - 1;
    {
        uint8 maxRange = v.baseLPTokenIndex + v.baseTokensLength;
        require(
            tokenIndexFrom < maxRange && tokenIndexTo < maxRange,
            "Token index out of range"
        );
    }

    if (tokenIndexFrom < v.baseLPTokenIndex) {
        // tokenFrom is from this pool
        v.x = xp[tokenIndexFrom].add(
            dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom])
        );
    } else {
        // tokenFrom is from the base pool
        tokenIndexFrom = tokenIndexFrom - v.baseLPTokenIndex;
        if (tokenIndexTo < v.baseLPTokenIndex) {
            uint256[] memory baseInputs = new uint256[](v.baseTokensLength);
            baseInputs[tokenIndexFrom] = dx;
            v.x = v
                .baseSwap
                .calculateTokenAmount(address(this), baseInputs, true)
                .mul(v.baseVirtualPrice)
                .div(BASE_VIRTUAL_PRICE_PRECISION)
                .add(xp[v.baseLPTokenIndex]);
        } else {
            // both from and to are from the base pool
            return
                v.baseSwap.calculateSwap(
                    tokenIndexFrom,
                    tokenIndexTo - v.baseLPTokenIndex,
                    dx
                );
        }
        tokenIndexFrom = v.baseLPTokenIndex;
    }

    v.metaIndexTo = v.baseLPTokenIndex;
    if (tokenIndexTo < v.baseLPTokenIndex) {
        v.metaIndexTo = tokenIndexTo;
    }

    {
        uint256 y = getY(
            getAPrecise(self),
            tokenIndexFrom,
            v.metaIndexTo,
            v.x,
            xp
        );
        v.dy = xp[v.metaIndexTo].sub(y).sub(1);
        uint256 dyFee = v.dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        v.dy = v.dy.sub(dyFee);
    }

    if (tokenIndexTo < v.baseLPTokenIndex) {
        // tokenTo is from this pool
        v.dy = v.dy.div(self.tokenPrecisionMultipliers[v.metaIndexTo]);
    } else {
        // tokenTo is from the base pool
        v.dy = v.baseSwap.calculateRemoveLiquidityOneToken(
            address(this),
            v.dy.mul(BASE_VIRTUAL_PRICE_PRECISION).div(v.baseVirtualPrice),
            tokenIndexTo - v.baseLPTokenIndex
        );
    }

    return v.dy;
}
