// Unchanged from uni (but getAmountsOut calculates uni/xybk invariant)
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
)
    external
    virtual
    override
    ensure(deadline)
    nonReentrant
    returns (uint256[] memory amounts)
{
    amounts = ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
    require(
        amounts[amounts.length - 1] >= amountOutMin,
        "ImpossibleRouter: INSUFFICIENT_OUTPUT_AMOUNT"
    );

    TransferHelper.safeTransferFrom(
        path[0],
        msg.sender,
        ImpossibleLibrary.pairFor(factory, path[0], path[1]),
        amounts[0]
    );
    _swap(amounts, path, to);
}
