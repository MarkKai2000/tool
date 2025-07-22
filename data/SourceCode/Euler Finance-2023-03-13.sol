/// @notice Donate eTokens to the reserves
/// @param subAccountId 0 for primary, 1-255 for a sub-account
/// @param amount In internal book-keeping units (as returned from balanceOf).
function donateToReserves(uint subAccountId, uint amount) external nonReentrant {
    (address underlying, AssetStorage storage assetStorage, address proxyAddr, address msgSender) = CALLER();
    address account = getSubAccount(msgSender, subAccountId);

    updateAverageLiquidity(account);
    emit RequestDonate(account, amount);

    AssetCache memory assetCache = loadAssetCache(underlying, assetStorage);

    uint origBalance = assetStorage.users[account].balance;
    uint newBalance;

    if (amount == type(uint).max) {
        amount = origBalance;
        newBalance = 0;
    } else {
        require(origBalance >= amount, "e/insufficient-balance");
        unchecked { newBalance = origBalance - amount; }
    }

    assetStorage.users[account].balance = encodeAmount(newBalance);
    assetStorage.reserveBalance = assetCache.reserveBalance = encodeSmallAmount(assetCache.reserveBalance + amount);

    emit Withdraw(assetCache.underlying, account, amount);
    emitViaProxy_Transfer(proxyAddr, account, address(0), amount);

    logAssetStatus(assetCache);
}