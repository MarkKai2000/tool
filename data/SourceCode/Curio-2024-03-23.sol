function cook(
    address _cgt,
    uint amount,
    uint wethMin,
    uint daiMin
) external onlyPans {
    cgt = IERC20(_cgt);
    cgt.transferFrom(msg.sender, address(this), amount);
    cgt.approve(address(chief), amount);
    chief.lock(amount);
    address[] memory yays = new address[](1);
    yays[0] = address(this);
    chief.vote(yays);
    chief.lift(address(this));

    spell = new Spell();
    address spelladdr = address(spell);
    bytes32 tag;
    assembly {
        tag := extcodehash(spelladdr)
    }
    uint delay = block.timestamp + 0;
    bytes memory sig = abi.encodeWithSignature(
        "act(address,address)",
        address(this),
        address(cgt)
    );
    pause.plot(address(spell), tag, sig, delay);
    pause.exec(address(spell), tag, sig, delay);

    _swap0();
    _swap1();

    require(weth.balanceOf(address(this)) >= wethMin, "not enought weth");
    require(dai.balanceOf(address(this)) >= daiMin, "not enought dai");

    _toBsc();
    _toSkale();
    _toPolkadot();
    _toBoba();

    weth.transfer(pans, weth.balanceOf(address(this)));
    dai.transfer(pans, dai.balanceOf(address(this)));
    cgt.transfer(pans, cgt.balanceOf(address(this)));

    sig = abi.encodeWithSignature("clean(address)", address(cgt));
    pause.plot(address(spell), tag, sig, delay);
    pause.exec(address(spell), tag, sig, delay);
}

function plot(
    bytes4 function_selector,
    uint256 varg1,
    uint256 varg2,
    uint256 varg3,
    uint256 varg4
) public payable {
    require(msg.data.length - 4 >= 128);
    require(varg3 <= 0x100000000);
    require(4 + varg3 + 32 <= 4 + (msg.data.length - 4));
    require(
        !((varg3.length > 0x100000000) |
            (36 + varg3 + varg3.length > 4 + (msg.data.length - 4)))
    );
    v0 = new bytes[](varg3.length);
    CALLDATACOPY(v0.data, 36 + varg3, varg3.length);
    v0[varg3.length] = 0;
    v1 = 0x1473(
        0xffffffff00000000000000000000000000000000000000000000000000000000 &
            function_selector,
        msg.sender
    );
    require(v1, Error("ds-auth-unauthorized"));
    require(
        block.timestamp + _delay >= block.timestamp,
        Error("ds-pause-addition-overflow")
    );
    require(
        varg4 >= block.timestamp + _delay,
        Error("ds-pause-delay-not-respected")
    );
    v2 = 0x16cc(varg4, v0, varg2, address(varg1));
    _plans[v2] = 0x1 | (~0xff & _plans[v2]);
    v3 = new array[](msg.data.length);
    v3[msg.data.length] = 0;
    emit ~0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff &
        (0xffffffff00000000000000000000000000000000000000000000000000000000 &
            function_selector)(msg.sender, varg1, varg2, msg.value, v3);
}

function exec(bytes4 function_selector, uint256 varg1, uint256 varg2, uint256 varg3, uint256 varg4) public payable { 
  require(msg.data.length - 4 >= 128);
  require(varg3 <= 0x100000000);
  require(4 + varg3 + 32 <= 4 + (msg.data.length - 4));
  require(!((varg3.length > 0x100000000) | (36 + varg3 + varg3.length > 4 + (msg.data.length - 4))));
  v0 = new bytes[](varg3.length);
  CALLDATACOPY(v0.data, 36 + varg3, varg3.length);
  v0[varg3.length] = 0;
  v1 = 0x16cc(varg4, v0, varg2, address(varg1));
  require(0xff & _plans[v1], Error('ds-pause-unplotted-plan'));
  require(EXTCODEHASH(address(varg1)) == varg2, Error('ds-pause-wrong-codehash'));
  require(block.timestamp >= varg4, Error('ds-pause-premature-exec'));
  v2 = 0x16cc(varg4, v0, varg2, address(varg1));
  _plans[v2] = 0x0 | ~0xff & _plans[v2];
  v3 = new array[](v0.length);
  v4 = v5 = 0;
  while (v4 < v0.length) {
    v3[v4] = v0[v4];
    v4 = v4 + 32;
  }
  v6 = v7 = v0.length + v3.data;
  if (0x1f & v0.length) {
    MEM[v7 - (0x1f & v0.length)] = ~(256 ** (32 - (0x1f & v0.length)) - 1) & MEM[v7 - (0x1f & v0.length)];
  }
  require(_proxy.code.size);
  v8, v9 = _proxy.exec(address(varg1), v3).gas(msg.gas);
  require(v8); // checks call status, propagates error data on error
  RETURNDATACOPY(v9, 0, RETURNDATASIZE());
  MEM[64] = v9 + (RETURNDATASIZE() + 31 & ~0x1f);
  require(RETURNDATASIZE() >= 32);
  require(MEM[v9] <= 0x100000000);
  require(MEM[v9] + v9 + 32 <= v9 + RETURNDATASIZE());
  require(!((MEM[MEM[v9] + v9] > 0x100000000) | (MEM[v9] + v9 + 32 + MEM[MEM[v9] + v9] > v9 + RETURNDATASIZE())));
  v10 = v11 = 0;
  while (v10 < MEM[MEM[v9] + v9]) {
    MEM[MEM[64] + 32 + v10] = MEM[32 + (MEM[v9] + v9) + v10];
    v10 = v10 + 32;
  }
  v12 = v13 = MEM[MEM[v9] + v9] + (MEM[64] + 32);
  if (0x1f & MEM[MEM[v9] + v9]) {
    MEM[v13 - (0x1f & MEM[MEM[v9] + v9])] = ~(256 ** (32 - (0x1f & MEM[MEM[v9] + v9])) - 1) & MEM[v13 - (0x1f & MEM[MEM[v9] + v9])];
    v12 = v14 = 32 + (v13 - (0x1f & MEM[MEM[v9] + v9]));
  }
  require(_proxy.code.size);
  v15, v16 = _proxy.owner().gas(msg.gas);
  require(v15); // checks call status, propagates error data on error
  require(RETURNDATASIZE() >= 32);
  require(address(v16) == address(this), Error('ds-pause-illegal-storage-change'));
  v17 = new array[](msg.data.length);
  v17[msg.data.length] = 0;
  emit ~0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff & (0xffffffff00000000000000000000000000000000000000000000000000000000 & function_selector)(msg.sender, varg1, varg2, msg.value, v17);
  v18 = new array[](MEM[MEM[v9] + v9]);
  v19 = v20 = 0;
  while (v19 < MEM[MEM[v9] + v9]) {
    v18[v19] = MEM[32 + MEM[64] + v19];
    v19 = v19 + 32;
  }
  v21 = v22 = MEM[MEM[v9] + v9] + v18.data;
  if (0x1f & MEM[MEM[v9] + v9]) {
    MEM[v22 - (0x1f & MEM[MEM[v9] + v9])] = ~(256 ** (32 - (0x1f & MEM[MEM[v9] + v9])) - 1) & MEM[v22 - (0x1f & MEM[MEM[v9] + v9])];
  }
  return v18, v23, msg.data.length;
}
