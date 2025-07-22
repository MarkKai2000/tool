function migrate(uint amountLP) external  {

    (uint token0,uint token1) = migrateLP(amountLP);
    (uint eth,uint cell, ) = IUniswapV2Router01(LP_NEW).getReserves();     

    uint resoult = cell/eth;              
    token1 = resoult * token0;

    IERC20(CELL).approve(ROUTER_V2,token1);
    IERC20(WETH).approve(ROUTER_V2,token0);

    (uint tokenA, , ) = IUniswapV2Router01(ROUTER_V2).addLiquidity(
        WETH,
        CELL,
        token0,
        token1,
        0,
        0,
        msg.sender,
        block.timestamp + 5000
    );

    uint balanceOldToken = IERC20(OLD_CELL).balanceOf(address(this));
    IERC20(OLD_CELL).transfer(marketingAddress,balanceOldToken);

    if (tokenA < token0) {
        uint256 refund0 = token0 - tokenA;
        IERC20(WETH).transfer(msg.sender,refund0);
    }
}

function migrateLP(uint amountLP) internal returns(uint256 token0,uint256 token1) {

    IERC20(LP_OLD).transferFrom(msg.sender,address(this),amountLP);
    IERC20(LP_OLD).approve(ROUTER_V2,amountLP);

    return IUniswapV2Router01(ROUTER_V2).removeLiquidity(
        WETH,
        OLD_CELL,
        amountLP,
        0,
        0,
        address(this),
        block.timestamp + 5000
    );

}