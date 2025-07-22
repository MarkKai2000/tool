function swapThroughOrionPool(
    uint112     amount_spend,
    uint112     amount_receive,
    address[]   calldata path,
    bool        is_exact_spend
) public payable nonReentrant {
    bool isCheckPosition = LibPool.doSwapThroughOrionPool(
        IPoolFunctionality.SwapData({
            amount_spend: amount_spend,
            amount_receive: amount_receive,
            is_exact_spend: is_exact_spend,
            supportingFee: false,
            path: path,
            orionpool_router: _orionpoolRouter,
            isInContractTrade: false,
            isSentETHEnough: false,
            isFromWallet: false,
            asset_spend: address(0)
        }),
        assetBalances, liabilities);
    if (isCheckPosition) {
        require(checkPosition(msg.sender), "E1PS");
    }
}

function depositAsset(address assetAddress, uint112 amount) external {
    uint256 actualAmount = IERC20(assetAddress).balanceOf(address(this));
    IERC20(assetAddress).safeTransferFrom(
        msg.sender,
        address(this),
        uint256(amount)
    );
    actualAmount = IERC20(assetAddress).balanceOf(address(this)) - actualAmount;
    generalDeposit(assetAddress, uint112(actualAmount));
}