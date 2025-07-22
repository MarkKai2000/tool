function claim(address _from, uint _amount) external {
    require(gamemasters[msg.sender] || npcs[msg.sender], "!gm");
    _burn(_from, _amount);
}

function _burn(address account, uint amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _balances[account] = _balances[account].sub(
        amount,
        "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
}
