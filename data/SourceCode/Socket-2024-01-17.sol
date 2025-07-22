function performAction(
    address fromToken,
    address toToken,
    uint256 amount,
    address receiverAddress,
    bytes calldata swapExtraData
) external payable override returns (uint256) {
    if (fromToken == address(0)) {
        revert Address0Provided();
    }

    bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

    uint256 _initialBalanceTokenOut;
    uint256 _finalBalanceTokenOut;

    ERC20 erc20ToToken = ERC20(toToken);
    if (toToken != NATIVE_TOKEN_ADDRESS) {
        _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
    } else {
        _initialBalanceTokenOut = address(this).balance;
    }

    if (fromToken != NATIVE_TOKEN_ADDRESS) {
        ERC20 token = ERC20(fromToken);
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(zeroXExchangeProxy, amount);

        // solhint-disable-next-line
        (bool success, ) = zeroXExchangeProxy.call(swapCallData);

        if (!success) {
            revert SwapFailed();
        }
        token.safeApprove(zeroXExchangeProxy, 0);
    } else {
        (bool success, ) = zeroXExchangeProxy.call{value: amount}(swapCallData);
        if (!success) {
            revert SwapFailed();
        }
    }

    if (toToken != NATIVE_TOKEN_ADDRESS) {
        _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
    } else {
        _finalBalanceTokenOut = address(this).balance;
    }

    uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

    if (toToken == NATIVE_TOKEN_ADDRESS) {
        payable(receiverAddress).transfer(returnAmount);
    } else {
        erc20ToToken.transfer(receiverAddress, returnAmount);
    }

    emit SocketSwapTokens(
        fromToken,
        toToken,
        returnAmount,
        amount,
        ZeroXIdentifier,
        receiverAddress
    );

    return returnAmount;
}
