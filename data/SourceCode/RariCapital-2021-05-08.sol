/**
 * @return Boolean indicating success!
 */

function deposit() external payable returns (bool) {
    require(_depositTo(msg.sender, msg.value), "Deposit failed.");
    return true;
}

function _depositTo(
    address to,
    uint256 amount
) internal fundEnabled returns (bool) {
    require(amount > 0, "Deposit amount must be greater than 0.");

    uint256 reptTotalSupply = varFundToken.totalSupply();

    uint256 fundBalance = reptTotalSupply > 0 ? getFundBalance() : 0; // Only set if used
    uint256 reptAmount = 0;

    if (reptTotalSupply > 0 && fundBalance > 0) {
        reptAmount = amount.mul(reptTotalSupply).div(fundBalance);
    } else {
        reptAmount = amount;
    }

    require(
        reptAmount > 0,
        "Deposit amount is so small that no REPT would be minted."
    );

    // Update net deposits, transfer funds from msg.sender, mint REPT, emit event, and return true
}
