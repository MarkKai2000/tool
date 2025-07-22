function sell(bool max) public nonReentrant returns (uint256 amountReturnedLP) {
    require(max, "sell function not called correctly");

    uint256 amountArray = balanceOf(msg.sender);

    amountReturnedLP = _sell(amountArray);
}

function _sell(
    uint256 amountArray
) internal returns (uint256 amountReturnedLP) {
    require(amountArray <= balanceOf(msg.sender), "user balance < amount");

    // calculate how much of the LP token the burner gets
    amountReturnedLP = calculateLPTokensGivenArrayTokens(amountArray);

    // burn token
    _burn(msg.sender, amountArray);

    // send to user
    require(
        arraySmartPool.transfer(msg.sender, amountReturnedLP),
        "transfer of lp token to user failed"
    );

    emit Sell(msg.sender, amountArray, amountReturnedLP);
}

function calculateLPTokensGivenArrayTokens(
    uint256 amount
) public view returns (uint256 amountLPToken) {
    // Calculate quantity of ARRAY minted based on total LP tokens
    return
        amountLPToken = bancorFormula.saleTargetAmount(
            totalSupply(),
            arraySmartPool.totalSupply(),
            reserveRatio,
            amount
        );
}
function joinPool(
    uint poolAmountOut,
    uint[] calldata maxAmountsIn
) external logs lock needsBPool lockUnderlyingPool {
    // ...
    // ...

    uint[] memory actualAmountsIn = SmartPoolManager.joinPool(
        IConfigurableRightsPool(address(this)),
        bPool,
        poolAmountOut,
        maxAmountsIn
    );

    // After createPool, token list is maintained in the underlying BPool
    address[] memory poolTokens = bPool.getCurrentTokens();

    for (uint i = 0; i < poolTokens.length; i++) {
        address t = poolTokens[i];
        uint tokenAmountIn = actualAmountsIn[i];

        emit LogJoin(msg.sender, t, tokenAmountIn);
        _pullUnderlying(t, msg.sender, tokenAmountIn);
    }

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
}
