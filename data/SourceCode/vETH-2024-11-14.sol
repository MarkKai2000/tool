function takeLoan(
    address to,
    uint256 amount
) external payable nonReentrant onlyValidFactory {
    if (block.number > lastLoanBlock) {
        lastLoanBlock = block.number;
        loanedAmountThisBlock = 0;
    }
    require(
        loanedAmountThisBlock + amount <= MAX_LOAN_PER_BLOCK,
        "Loan limit per block exceeded"
    );

    loanedAmountThisBlock += amount;
    _mint(to, amount);
    _increaseDebt(to, amount);

    emit LoanTaken(to, amount);
}
