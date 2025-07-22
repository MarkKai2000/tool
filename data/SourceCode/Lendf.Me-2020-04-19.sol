function _transferFrom(
    address holder,
    address recipient,
    uint256 amount
) internal returns (bool) {
    require(recipient != address(0), "ERC777: transfer to the zero address");
    require(holder != address(0), "ERC777: transfer from the zero address");

    address spender = msg.sender;

    // Notify holder (Hijacked!)
    _callTokensToSend(spender, holder, recipient, amount, "", "");

    // Update balances of holder & recipient
    _move(spender, holder, recipient, amount, "", "");

    _approve(holder, spender, _allowances[holder][spender].sub(amount));

    _callTokensReceived(spender, holder, recipient, amount, "", "", false);

    return true;
}
