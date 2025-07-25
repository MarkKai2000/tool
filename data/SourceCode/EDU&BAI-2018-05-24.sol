function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    // same as above
    require(_to != 0x0);
    require(balances[_from] = _value);
    require(balances[_to] + _value  balances[_to]);

    uint previousBalances = balances[_from] + balances[_to];
    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    assert(balances[_from] + balances[_to] == previousBalances);

    return true;
}