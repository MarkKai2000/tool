function deposit(address _userAddress, uint256 _wantAmt) public nonPayable {
    require(msg.data.length - 4 >= 64);

    v0 = v1 = _tokenBalance[_userAddress].field0_0_0;
    if (!v1) {
        v0 = v2 = _tokenBalance[_userAddress].field0_1_1;
    }

    require(v0);
    require(_wantAmt);

    v3 = 0x371b(_userAddress, _wantAmt);
    require(v3);

    v4 = 0x3039(_userAddress, v3);
    require(v4);

    0x37b4(_userAddress, msg.sender, this, _wantAmt);

    v5 = _SafeAdd(_tokenBalance[_userAddress].field1, _wantAmt);
    _tokenBalance[_userAddress].field1 = v5;

    if (_tokenBalance[_userAddress].field0_0_0) {
        v6 = _SafeAdd(_totalReserves, v3);
        _totalReserves = v6;
        emit ReservesUpdated(v6);
    }

    require((address(stor_6)).code.size);

    v7 = MEM[64];
    v8 = v9 = address(stor_6).mint(msg.sender, v4).gas(msg.gas);

    require(v8, v9, RETURNDATASIZE());

    if (v8) {
        require(v7 <= uint64.max, Panic(65)); // failed memory allocation (too much memory)
    }

    emit Deposit(_userAddress, _wantAmt, v3, v4);
    return v4;
}
