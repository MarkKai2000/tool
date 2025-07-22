function exchange(uint256 amount) public payable {  find similar
    require(4 + (msg.data.length - 4) - 4 >= 32);
    0x2a44(amount);
    require(msg.sender.code.size <= 0, Error('no isContract'));
    require(amount >= stor_9, Error('num >= propor'));
    v0 = _SafeAdd(amount, owner_a[msg.sender]);
    owner_a[msg.sender] = v0;
    0x1a69(amount, stor_10_0_19, msg.sender, _usdt);
    require(bool(owner_e_0_19.code.size));
    v1, /* address */ v2, /* address */ v3, /* address */ v4 = owner_e_0_19.staticcall(uint32(0xbd52993b), msg.sender).gas(msg.gas);
    require(bool(v1), 0, RETURNDATASIZE()); // checks call status, propagates error data on error
    MEM[64] = MEM[64] + (RETURNDATASIZE() + 31 & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0);
    require(MEM[64] + RETURNDATASIZE() - MEM[64] >= 96);
    0x2a16(v2);
    0x2a16(v3);
    0x2a16(v4);
    v5 = 0x1201();
    v6 = 0x1af2(amount, v5);
    v7 = 0x1b6d(10 ** 18, v6);
    v8 = v9 = 0;
    if (address(v2) != address(v9)) {
        v10 = 0x1af2(_one, v7);
        v11 = 0x1b6d(_exchange, v10);
        v8 = v12 = _SafeAdd(v11, v9);
        v13 = _SafeAdd(v11, owner_b[address(v2)]);
        owner_b[address(v2)] = v13;
    }
    if (address(v3) != address(0x0)) {
        v14 = 0x1af2(_two, v7);
        v15 = 0x1b6d(_exchange, v14);
        v8 = v16 = _SafeAdd(v15, v8);
        v17 = _SafeAdd(v15, owner_b[address(v3)]);
        owner_b[address(v3)] = v17;
    }
    if (address(v4) != address(0x0)) {
        v18 = 0x1af2(_three, v7);
        v19 = 0x1b6d(_exchange, v18);
        v8 = v20 = _SafeAdd(v19, v8);
        v21 = _SafeAdd(v19, owner_b[address(v4)]);
        owner_b[address(v4)] = v21;
    }
    v22 = 0x1af2(stor_8, v7);
    v23 = 0x1b6d(_exchange, v22);
    v24 = _SafeAdd(v23, v8);
    0x1972(v23, stor_f_0_19, _kpt);
    v25 = _SafeSub(v24, v7);
    0x1972(v25, msg.sender, _kpt);
}