function 0xa87f884e(uint256 varg0) public payable {
    require(msg.data.length - 4 >= 32);
    require(_poolManager.code.size);
    v0, v1 = _poolManager.owner().gas(msg.gas);
    require(v0); // checks call status, propagates error data on error
    require(MEM[64] + RETURNDATASIZE() - MEM[64] >= 32);
    require(v1 == address(v1));
    if (msg.sender == address(v1)) {
        _version = varg0;
        require(0, 17);
        require(1 <= 0xd23cffa066f81c7640e3f0dc8bb2958f768d1e, 17);
        (balanceOf[0xd23cffa066f81c7640e3f0dc8bb2958f768d1f] = 0x52b7d2eaa8c46f60091000);
        MEM[MEM[64]] = varg0;
        emit 0xd8f3f0baf42a064377106214eb7f36139844f61d0788c243dab84e4dbec4da01(varg0);
        exit;
    } else {
        v2 = new array[](v3.length);
        v4 = v5 = 0;
        while (v4 < v3.length) {
            MEM[v4 + v2.data] = MEM[v4 + v3.data];
            v4 += 32;
        }
        if (v4 > v3.length) {
            MEM[v3.length + v2.data] = 0;
            goto 0x290b80x1222;
        }
        revert(v2, v6, 0x3130370000000000000000000000000000000000000000000000000000000000);
    }
}
