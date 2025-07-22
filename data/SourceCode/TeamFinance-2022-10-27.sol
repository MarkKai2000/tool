function migrate(
    uint256 id,
    IV3Migrator.MigrateParams calldata params,
    bool noLiquidity,
    uint160 sqrtPriceX96,
    bool _mintNFT
) external payable whenNotPaused nonReentrant {
    require(
        address(nonfungiblePositionManager) != address(0),
        "NFT manager not set"
    );
    require(address(v3Migrator) != address(0), "v3 migrator not set");
    Items memory lockedERC20 = lockedToken[id];
    require(
        block.timestamp < lockedERC20.unlockTime,
        "Unlock time already reached"
    );
    require(msg.sender == lockedERC20.withdrawalAddress, "Unauthorised sender");
    require(!lockedERC20.withdrawn, "Already withdrawn");
}
