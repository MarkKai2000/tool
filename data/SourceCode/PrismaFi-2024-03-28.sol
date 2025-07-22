function onFlashLoan(
    address,
    address,
    uint256 amount,
    uint256 fee,
    bytes calldata data
) external returns (bytes32) {
    require(msg.sender == address(debtToken), "!DebtToken");
    (
        address account,
        address troveManagerFrom,
        address troveManagerTo,
        uint256 maxFeePercentage,
        uint256 coll,
        address upperHint,
        address lowerHint
    ) = abi.decode(
            data,
            (address, address, address, uint256, uint256, address, address)
        );
    uint256 toMint = amount + fee;
    borrowerOps.closeTrove(troveManagerFrom, account);
    borrowerOps.openTrove(
        troveManagerTo,
        account,
        maxFeePercentage,
        coll,
        toMint,
        upperHint,
        lowerHint
    );
    return _RETURN_VALUE;
}
