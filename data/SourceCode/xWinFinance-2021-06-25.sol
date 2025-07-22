function _swapBNBToTokens(
    address toDest,
    uint amountIn,
    uint deadline,
    address destAddress,
    uint priceImpactTolerance
) internal returns (uint) {
    address[] memory path = new address[](2);
    path[0] = pancakeSwapRouter.WETH();
    path[1] = toDest;

    (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(
        pancakeSwapRouter.factory(),
        path[0],
        path[1]
    );
    uint quote = PancakeLibrary.quote(amountIn, reserveA, reserveB);

    uint[] memory amounts = pancakeSwapRouter.swapExactETHForTokens{
        value: amountIn
    }(
        quote.sub(quote.mul(priceImpactTolerance).div(10000)),
        path,
        destAddress,
        deadline
    );

    return amounts[amounts.length - 1];
}
