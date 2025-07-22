function mint(address _token, uint256 _amount) external {
    require(!paused[_token], "SYS002");
    _mint(msg.sender, _token, _amount);
}

function _mint(address _sender, uint256 _amount) internal {
    (, uint256 uniBTCAmount) = _amounts(_amount);
    require(uniBTCAmount > 0, "USR010");

    uint256 totalSupply = ISupplyFeeder(supplyFeeder).totalSupply(NATIVE_BTC);
    require(totalSupply <= caps[NATIVE_BTC], "USR003");

    IMintableContract(uniBTC).mint(_sender, uniBTCAmount);

    emit Minted(NATIVE_BTC, _amount);
}

function _amounts(uint256 _amount) internal returns (uint256, uint256) {
    uint256 uniBTCAmt = _amount / EXCHANGE_RATE_BASE;
    return (uniBTCAmt * EXCHANGE_RATE_BASE, uniBTCAmt);
}
