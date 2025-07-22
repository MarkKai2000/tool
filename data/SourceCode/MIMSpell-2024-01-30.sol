function repayForAll(uint128 amount, bool skim) public returns (uint128) {
    accrue();

    if (skim) {
        // ignore amount and take every mim in this contract since it could be taken by anyone, the next block.
        amount = uint128(magicInternetMoney.balanceOf(address(this)));
        bentoBox.deposit(
            magicInternetMoney,
            address(this),
            address(this),
            amount,
            0
        );
    } else {
        bentoBox.transfer(
            magicInternetMoney,
            msg.sender,
            address(this),
            bentoBox.toShare(magicInternetMoney, amount, true)
        );
    }

    uint128 previousElastic = totalBorrow.elastic;

    require(previousElastic - amount > 1000 * 1e18, "Total Elastic too small");

    totalBorrow.elastic = previousElastic - amount;

    emit LogRepayForAll(amount, previousElastic, totalBorrow.elastic);
    return amount;
}
