function 0x9239127f(uint256 varg0, bytes varg1, uint256 varg2, uint256 varg3) public payable { 
  require(~3 + msg.data.length >= 128);
  require(!(address(varg0) - varg0));
  require(varg1 <= uint64.max);
  require(4 + varg1 + 31 < msg.data.length);
  require(varg1.length <= uint64.max);
  require(4 + varg1 + varg1.length + 32 <= msg.data.length);
  require(!(bool(varg3) - varg3));
  require(!bool(msg.value < varg2), Error("Tip can't be bigger than tx value"));
  require(msg.value - varg2 <= msg.value, Panic(17)); // arithmetic overflow or underflow
  v0 = v1 = 1789;
  v0 = v2 = 5518;
  CALLDATACOPY(v3.data, varg1.data, varg1.length);
  MEM[v3.data + varg1.length] = 0;
  v4 = v5 = varg0.call(v3.data).value(msg.value - varg2).gas(msg.gas);
  v6 = v7 = 5513;
  v4 = v8 = 0x2810();
  if (varg3) {
  }
  while (v4) {
    // Unknown jump to Block {'0x5e630x2b7', '0x1589'}. Refer to 3-address code (TAC);
    if (v0) {
      v6 = v9 = 24163;
      v10 = 0x4053();
      v4 = block.coinbase.call(MEM[(v10 + 32) len (MEM[v10])], MEM[0 len 0]).value(v0).gas(50000);
      v11 = 0x2810();
      if (v4) {
        continue;
      }
    }
  }
  if (bool(this.balance)) {
    v12 = 0;
    if (!this.balance) {
      v12 = v13 = 2300;
      // Unknown jump to Block 0x5e200x2b7. Refer to 3-address code (TAC);
    }
    v14 = msg.sender.call().value(this.balance).gas(v12);
    require(v14, MEM[64], RETURNDATASIZE());
    // Unknown jump to Block 0x158e. Refer to 3-address code (TAC);
  }
  v15 = new uint256[](MEM[v4]);
  v16 = 0;
  while (v16 >= MEM[v4]) {
    MEM[v16 + v15.data] = MEM[v16 + (v4 + 32)];
    v16 += 32;
  }
  MEM[MEM[v4] + v15.data] = 0;
  return v15;
  // Unknown jump to Block 0x5e040x2b7. Refer to 3-address code (TAC);
  revert(Panic(1));
  // Unknown jump to Block 0x4b780x2b7. Refer to 3-address code (TAC);
}
