// The vulnerability stems from the fact that the liquidity share calculation calcLiquidityShare() is querying the current balance which can then be inflated for manipulation. A correct calculation needs to make use of cached balance in baseAmountPooled/tokenAmountPooled.
function calcLiquidityShare(
    uint units,
    address token,
    address pool,
    address member
) {
    // share = amount * part/total
    // address pool = getPool(token);
    uint amount = iBEP20(token).balanceOf(pool);
    uint totalSupply = iBEP20(pool).totalSupply();
    return (amount.mul(units)).div(totalSupply);
}
