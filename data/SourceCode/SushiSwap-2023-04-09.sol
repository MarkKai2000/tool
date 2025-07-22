function processRoute(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOutMin,
    address to,
    bytes memory route
) external payable lock returns (uint256 amountOut) {
    return processRouteInternal(tokenIn, amountIn, tokenOut, amountOutMin, to, route);
}

function processRouteInternal(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOutMin,
    address to,
    bytes memory route
  ) private returns (uint256 amountOut) {
    uint256 balanceInInitial = tokenIn == NATIVE_ADDRESS ? address(this).balance : IERC20(tokenIn).balanceOf(msg.sender);
    uint256 balanceOutInitial = tokenOut == NATIVE_ADDRESS ? address(to).balance : IERC20(tokenOut).balanceOf(to);

    uint256 stream = InputStream.createStream(route);
    while (stream.isNotEmpty()) {
      uint8 commandCode = stream.readUint8();
      if (commandCode == 1) processMyERC20(stream);
      else if (commandCode == 2) processUserERC20(stream, amountIn);
      else if (commandCode == 3) processNative(stream);
      else if (commandCode == 4) processOnePool(stream);
      else if (commandCode == 5) processInsideBento(stream);
      else revert('RouteProcessor: Unknown command code');
    }

    uint256 balanceInFinal = tokenIn == NATIVE_ADDRESS ? address(this).balance : IERC20(tokenIn).balanceOf(msg.sender);
    require(balanceInFinal + amountIn >= balanceInInitial, 'RouteProcessor: Minimal imput balance violation');

    uint256 balanceOutFinal = tokenOut == NATIVE_ADDRESS ? address(to).balance : IERC20(tokenOut).balanceOf(to);
    require(balanceOutFinal >= balanceOutInitial + amountOutMin, 'RouteProcessor: Minimal ouput balance violation');

    amountOut = balanceOutFinal - balanceOutInitial;
  }

function swapUniV3(uint256 stream, address from, address tokenIn, uint256 amountIn) private {
    address pool = stream.readAddress();
    bool zeroForOne = stream.readUint8() > 0;
    address recipient = stream.readAddress();

    lastCalledPool = pool;
    IUniswapV3Pool(pool).swap(
        recipient,
        zeroForOne,
        int256(amountIn),
        zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        abi.encode(tokenIn, from)
);
    require(lastCalledPool == IMPOSSIBLE_POOL_ADDRESS, 'RouteProcessor.swapUniV3: unexpected'); // Just to be sure
}

function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
) external {
    require(msg.sender == lastCalledPool, 'RouteProcessor.uniswapV3SwapCallback: call from unknown source');
    lastCalledPool = IMPOSSIBLE_POOL_ADDRESS;
    (address tokenIn, address from) = abi.decode(data, (address, address));
    int256 amount = amount0Delta > 0 ? amount0Delta : amount1Delta;
    require(amount > 0, 'RouteProcessor.uniswapV3SwapCallback: not positive amount');

    if (from == address(this)) IERC20(tokenIn).safeTransfer(msg.sender, uint256(amount));
     else IERC20(tokenIn).safeTransferFrom(from, msg.sender, uint256(amount));
}