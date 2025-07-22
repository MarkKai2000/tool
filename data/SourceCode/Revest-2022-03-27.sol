function handleMultipleDeposits(
    uint fnftId,
    uint newFNFTId,
    uint amount
) external override onlyRevestController {
    require(amount >= fnfts[fnftId].depositAmount, "E003");
    IRevest.FNFTConfig storage config = fnfts[fnftId];
    config.depositAmount = amount;
    mapFNFTToToken(fnftId, config);
    if (newFNFTId != 0) {
        mapFNFTToToken(newFNFTId, config);
    }
}
