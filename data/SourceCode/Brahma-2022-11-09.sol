function zapIn(
    ZapData calldata zapCall
) external payable nonReentrant isRelevant {
    if (zapCall.requiredToken != nativeETH) {
        IERC20(zapCall.requiredToken).transferFrom(
            msg.sender,
            address(this),
            zapCall.amountIn
        );
    }

    uint256 amountIn = zap(zapCall, true);

    IERC20(wantToken()).approve(address(vault), amountIn);
    uint256 sharesOut = vault.deposit(amountIn, msg.sender);

    emit ZappedIn(
        zapCall.requiredToken,
        msg.sender,
        zapCall.amountIn,
        sharesOut
    );
}

function zap(
    ZapData memory zapCall,
    bool deposit
) internal returns (uint256 tokenOut) {
    if (zapCall.requiredToken == wantToken()) {
        return zapCall.amountIn;
    }

    address inputToken = deposit ? zapCall.requiredToken : wantToken();
    address outputToken = deposit ? wantToken() : zapCall.requiredToken;
    uint256 oldBalance = ERC20(outputToken).balanceOf(address(this));

    if (inputToken == nativeETH) {
        require(msg.value >= zapCall.amountIn, "ETH_NOT_RECEIVED");

        (bool success, ) = zapCall.swapTarget.call{value: zapCall.amountIn}(
            zapCall.callData
        );
        require(success, "SWAP_FAILED");
    } else {
        require(
            ERC20(inputToken).balanceOf(address(this)) >= zapCall.amountIn,
            "INPUT_AMOUNT_NOT_RECEIVED"
        );

        ERC20(inputToken).approve(zapCall.allowanceTarget, zapCall.amountIn);

        (bool success, ) = zapCall.swapTarget.call(zapCall.callData);
        require(success, "SWAP_FAILED");
    }

    uint256 newBalance = ERC20(outputToken).balanceOf(address(this));
    tokenOut = newBalance - oldBalance;

    require(tokenOut >= zapCall.minAmountOut, "MIN_AMOUNT_NOT_RECEIVED");
}
