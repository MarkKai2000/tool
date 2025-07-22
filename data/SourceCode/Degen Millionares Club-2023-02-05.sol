function mintFromStaking(address to, uint256 amount) external {
    
    excludeAccountInt(to);

    _tTotal = _tTotal.add(amount);
    _rTotal = (MAX - (MAX % _tTotal));

    _tOwned[to] = _tOwned[to].add(amount);
    _rOwned[to] = _rOwned[to].add(amount);

    emit Transfer(address(0), to, amount);

    includeAccountInt(to);
}