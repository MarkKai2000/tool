function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address initiator,
    bytes calldata data
) external override returns (bool) {
    if (initiator != address(this)) revert CustomError("not-same-sender");
    if (msg.sender != address(POOL)) revert CustomError("not-aave-sender");

    FlashloanVars memory flashloanVars;
    (
        flashloanVars.opt,
        flashloanVars.dsaAddress,
        flashloanVars.collateralTokens,
        flashloanVars.collateralAmounts,
        flashloanVars.multiTokenSwapData
    ) = abi.decode(data, (bool, address, address[], uint256[], bytes[]));

    deloopInOneOrMultipleTransactions(
        flashloanVars.opt,
        flashloanVars.dsaAddress,
        assets,
        amounts,
        premiums,
        flashloanVars.collateralTokens,
        flashloanVars.collateralAmounts,
        flashloanVars.multiTokenSwapData
    );

    return true;
}

function deloopInOneOrMultipleTransactions(
    bool opt,
    address _dsaAddress,
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address[] memory collateralTokens,
    uint256[] memory collateralAmounts,
    bytes[] memory multiTokenSwapData
) private {
    // Repay all flashloan assets or withdraw all collaterals
    repayAllDebtAssetsWithFlashLoan(opt, _dsaAddress, assets, amounts);

    // Extract all collaterals
    extractAllCollaterals(_dsaAddress, collateralTokens, collateralAmounts);

    // Deloop all collaterals
    deloopAllCollaterals(multiTokenSwapData);

    // Repay all flashloan assets or withdraw all collaterals
    repayFlashloansAndTransferToTreasury(
        opt,
        _dsaAddress,
        assets,
        amounts,
        premiums
    );
}

function deloopAllCollaterals(bytes[] memory multiTokenSwapData) private {
    FlashloanVars memory flashloanVars;

    for (uint i = 0; i < multiTokenSwapData.length; ) {
        // Deloop
        (
            flashloanVars.srcToken,
            flashloanVars.destToken,
            flashloanVars.srcAmount,
            flashloanVars.destAmount,
            flashloanVars.paraSwapContract,
            flashloanVars.tokenTransferProxy,
            flashloanVars.paraswapCallData
        ) = _getParaswapData(multiTokenSwapData[i]);

        // using ParaSwap
        IERC20(flashloanVars.srcToken).safeIncreaseAllowance(
            flashloanVars.tokenTransferProxy,
            flashloanVars.srcAmount
        );
        (flashloanVars.sent, ) = flashloanVars.paraSwapContract.call(
            flashloanVars.paraswapCallData
        );
        if (!flashloanVars.sent) revert CustomError("ParaSwap deloop failed");

        unchecked {
            i++;
        }
    }
}
