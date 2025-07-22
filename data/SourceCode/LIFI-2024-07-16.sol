function depositToGasZipERC20(
    LibSwap.SwapData calldata _swapData,
    uint256 _destinationChains,
    address _recipient
) public {
    // get the current native balance
    uint256 currentNativeBalance = address(this).balance;

    // execute the swapData that swaps the ERC20 token into native
    LibSwap.swap(0, _swapData);

    // calculate the swap output amount using the initial native balance
    uint256 swapOutputAmount = address(this).balance - currentNativeBalance;

    // call the gas zip router and deposit tokens
    gasZipRouter.deposit{value: swapOutputAmount}(
        _destinationChains,
        _recipient
    );
}
