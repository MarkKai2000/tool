function withdraw(uint256 _shares) public {
    claim(msg.sender); // TODO double check inherited correctly
    _burn(msg.sender, _shares);
    uint avai = available();
    if (avai < _shares)
        IMasterMind(mastermind).withdraw(nrvPid, (_shares.sub(avai)));
    token.safeTransfer(msg.sender, _shares);
    emit Withdrawn(msg.sender, _shares, block.number);
    updateDebt(msg.sender);
}
function emergencyBurn() public {
    uint balan = balanceOf(msg.sender);
    uint avai = available();
    if (avai < balan)
        IMasterMind(mastermind).withdraw(nrvPid, (balan.sub(avai)));
    token.safeTransfer(msg.sender, balan);
    emit Withdrawn(msg.sender, balan, block.number);
}
