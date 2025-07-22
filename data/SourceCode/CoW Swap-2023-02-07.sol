function settle(
    IERC20[] calldata tokens,
    uint256[] calldata clearingPrices,
    GPv2Trade.Data[] calldata trades,
    GPv2Interaction.Data[][3] calldata interactions
) external nonReentrant onlySolver {
    executeInteractions(interactions[0]);

    (
        GPv2Transfer.Data[] memory inTransfers,
        GPv2Transfer.Data[] memory outTransfers
    ) = computeTradeExecutions(tokens, clearingPrices, trades);

    vaultRelayer.transferFromAccounts(inTransfers);

    executeInteractions(interactions[1]);

    vault.transferToAccounts(outTransfers);

    executeInteractions(interactions[2]);

    emit Settlement(msg.sender);
}