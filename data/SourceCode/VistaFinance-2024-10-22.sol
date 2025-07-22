function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
) public virtual override returns (bool) {
    require(
        amount <= maxFlashLoan(token),
        "ERC20FlashMint: amount exceeds maxFlashLoan"
    );
    uint256 fee = flashFee(token, amount);

    _mint(address(receiver), amount);
    require(
        receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
            _RETURN_VALUE,
        "ERC20FlashMint: invalid return value"
    );
    address flashFeeReceiver = _flashFeeReceiver();
    _spendAllowance(address(receiver), address(this), amount + fee);
    if (fee == 0 || flashFeeReceiver == address(0)) {
        _burn(address(receiver), amount + fee);
    } else {
        _burn(address(receiver), amount);
        _transfer(address(receiver), flashFeeReceiver, fee);
    }
    return true;
}
