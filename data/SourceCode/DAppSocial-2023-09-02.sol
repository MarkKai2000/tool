function withdrawTokensWithAlt(address varg0, address varg1, uint256 varg2) public nonPayable {
    require(msg.data.length - 4 >= 96);
    require(varg0 == varg0);
    require(varg1 == varg1);
    require(varg2 > 0, Error('Amount should be greater than 0'));
    require(varg2 <= _getTokenBalances[varg0][msg.sender], NotEnoughBalance());
    require(uint8(_depositTokens[address(varg0)]), TokenNotSupported());
    require(msg.sender == address(_unlockTokens[address(varg1)]), CallerNotApproved());
    _getTokenBalances[varg0][varg1] = _getTokenBalances[varg0][varg1] - varg2;
    0x203a(varg2, msg.sender, varg0);
    emit TokenWithdrawn(varg0, msg.sender, varg2);
}