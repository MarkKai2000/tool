function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
) external {
    // Check caller is the legit Uniswap pool
    address uniswapPool;
    assembly {
        uniswapPool := tload(1)
    }
    require(msg.sender == uniswapPool);

    // Decode data
    (
        address minter,
        address ape,
        SirStructs.VaultParameters memory vaultParams,
        SirStructs.VaultState memory vaultState,
        SirStructs.Reserves memory reserves,
        bool zeroForOne,
        bool isETH
    ) = abi.decode(
            data,
            (
                address,
                address,
                SirStructs.VaultParameters,
                SirStructs.VaultState,
                SirStructs.Reserves,
                bool,
                bool
            )
        );

    // Retrieve amount of collateral to deposit and check it does not exceed max
    (uint256 collateralToDeposit, uint256 debtTokenToSwap) = zeroForOne
        ? (uint256(-amount1Delta), uint256(amount0Delta))
        : (uint256(-amount0Delta), uint256(amount1Delta));

    // If this is an ETH mint, transfer WETH to the pool asap
    if (isETH) {
        TransferHelper.safeTransfer(
            vaultParams.debtToken,
            uniswapPool,
            debtTokenToSwap
        );
    }

    // Rest of the mint logic
    require(collateralToDeposit <= type(uint144).max);
    uint256 amount = _mint(
        minter,
        ape,
        vaultParams,
        uint144(collateralToDeposit),
        vaultState,
        reserves
    );

    // Transfer debt token to the pool
    // This is done last to avoid reentrancy attack from a bogus debt token contract
    if (!isETH) {
        TransferHelper.safeTransferFrom(
            vaultParams.debtToken,
            minter,
            uniswapPool,
            debtTokenToSwap
        );
    }

    // Use the transient storage to return amount of tokens minted to the mint function
    assembly {
        tstore(1, amount)
    }
}
