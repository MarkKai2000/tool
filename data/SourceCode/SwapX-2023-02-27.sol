function 0x4f1f05bc(uint256 varg0, uint256 varg1, uint256 varg2, uint256 varg3, address varg4) public payable { 
    v0 = v1 = 17583;
    require(msg.data.length - 4 >= 160);
    require(varg0 <= 0x100000000);
    require(varg0.data <= 4 + (msg.data.length - 4));
    v0 = v2 = varg0.length;
    v0 = v3 = varg0.data;
    require(!((v2 > 0x100000000) | (v3 + (v2 << 5) > 4 + (msg.data.length - 4))));
    require(varg3 <= 0x100000000);
    require(varg3.data <= 4 + (msg.data.length - 4));
    v0 = v4 = varg3.length;
    v0 = v5 = varg3.data;
    require(!((v4 > 0x100000000) | (v5 + (v4 << 5) > 4 + (msg.data.length - 4))));
    v0 = v6 = varg4;
    v0 = v7 = 0;
    v8 = v9 = 834;
    v0 = v10 = v2 + ~0;
    assert(v10 < v2);
    while (1) {
        v11 = 0xcfe(address(msg.data[(v0 << 5) + v0]));
        if (!v11) {
            MEM[MEM[64]] = 0x70a0823100000000000000000000000000000000000000000000000000000000;
            require(bool((address(address(address(msg.data[(v0 << 5) + v0])))).code.size));
            v12 = address(msg.data[(v0 << 5) + v0]).staticcall(v13, address(v0)).gas(msg.gas);
            if (bool(v12)) {
                v14 = new uint256[](v0);
                require(RETURNDATASIZE() >= 32);
                v0 = v15 = v14.length;
                // Unknown jump to Block {'0x45ea', '0x4be', '0x342'}. Refer to 3-address code (TAC);
            } else {
                RETURNDATACOPY(0, 0, RETURNDATASIZE());
                revert(0, RETURNDATASIZE());
            }
        } else {
            v0 = (address(v0)).balance;
            // Unknown jump to Block {'0x45ea', '0x4be', '0x342'}. Refer to 3-address code (TAC);
        }
        v0 = v16 = 1;
        if (v0 >= v0) {
            require(v0 >= v0, Error('SwapX: Return amount is not enough'));
            return v0;
        } else {
            assert(v0 < v0);
            assert(v0 - 1 < v0);
            if (address(msg.data[(v0 - 1 << 5) + v0]) != address(msg.data[(v0 << 5) + v0])) {
                require(v0 <= uint64.max);
                v0 = v17 = new uint256[](v0);
                if (v0) {
                    CALLDATACOPY(v14.data, msg.data.length, v0 << 5);
                }
                v18 = v19 = 0;
                while (v18 < v0) {
                    assert(v18 < v0);
                    assert(v18 < v14.length);
                    v14[v18] = uint8(msg.data[(v18 << 5) + v0] >> (v0 - 1 << 3));
                    v18 += 1;
                }
                assert(v0 - 1 < v0);
                assert(v0 < v0);
                if (1 != v0) {
                }
                if (v0 != v0 + ~0) {
                }
                if (address(msg.data[(v0 - 1 << 5) + v0]) != address(msg.data[(v0 << 5) + v0])) {
                    v20 = MEM[64];
                    MEM[64] = 512 + v20;
                    v21 = 16;
                    do {
                        MEM[v20] = 16704;
                        v20 += 32;
                        v21 = v21 - 1;
                    } while (!v21);
                    MEM[MEM[64]] = 3383;
                    MEM[32 + MEM[64]] = 3404;
                    MEM[64 + MEM[64]] = 3439;
                    MEM[96 + MEM[64]] = 3452;
                    MEM[128 + MEM[64]] = 3480;
                    MEM[160 + MEM[64]] = 3514;
                    MEM[192 + MEM[64]] = 3548;
                    MEM[224 + MEM[64]] = 3582;
                    MEM[256 + MEM[64]] = 3595;
                    MEM[288 + MEM[64]] = 3623;
                    MEM[320 + MEM[64]] = 3636;
                    MEM[352 + MEM[64]] = 3649;
                    MEM[384 + MEM[64]] = 3662;
                    MEM[416 + MEM[64]] = 3690;
                    MEM[448 + MEM[64]] = 3724;
                    MEM[480 + MEM[64]] = 3737;
                    require(v14.length <= 16, Error('SwapX: Distribution array should not exceed reserves array size'));
                    v22 = 0;
                    while (v22 < v14.length) {
                        assert(v22 < v14.length);
                        if (v14[v22] > 0) {
                            assert(v22 < v14.length);
                            v22 += v14[v22];
                            require(v22 >= v22, Error('SafeMath: addition overflow'));
                        }
                        v22 += 1;
                    }
                    if (v22) {
                        v23 = 0;
                        while (v23 < v14.length) {
                            assert(v23 < v14.length);
                            if (0 != v14[v23]) {
                                assert(v23 < v14.length);
                                if (v0) {
                                    v24 = v25 = v14[v23] * v0;
                                    assert(v0);
                                    require(v25 / v0 == v14[v23], Error('SafeMath: multiplication overflow'));
                                }
                                if (v22) {
                                    assert(v22);
                                    assert(v23 < 16);
                                } else {
                                    v26 = new bytes[](v27.length);
                                    v28 = v29 = v27.length;
                                    v30 = v31 = v26.data;
                                    v32 = v33 = v27.data;
                                    if (v29) {
                                        v34 = v27.data;
                                        v35 = v26.data;
                                        v26[0] = v27[0];
                                        v36 = v37 = 32;
                                    }
                                }
                            } else {
                                v23 += 1;
                            }
                        }
                    } else {
                        v38 = 0xcfe(address(msg.data[(v0 - 1 << 5) + v0]));
                        if (v38) {
                            v39 = address(v0).call().value(msg.value).gas(2300 * !msg.value);
                            if (!bool(v39)) {
                                RETURNDATACOPY(0, 0, RETURNDATASIZE());
                                revert(0, RETURNDATASIZE());
                            }
                        }
                    }
                }
                if (v0 == v0 + ~0) {
                    v0 = v40 = 1297;
                    v0 = v41 = 'swapMulti sub failed';
                    v8 = v42 = 17898;
                    assert(v0 < v0);
                } else {
                    v8 = v43 = 1214;
                    v0 = v44 = this;
                    assert(v0 < v0);
                }
            }
        }
        v0 += 1;
        // Unknown jump to Block 0x34a. Refer to 3-address code (TAC);
        v0 = v0 - v0;
        if (v0 <= v0) {
            // Unknown jump to Block 0x511. Refer to 3-address code (TAC);
        } else {
            v45 = new uint256[](MEM[v0]);
            v30 = v45.data;
            v28 = MEM[v0];
            v32 = 32 + v0;
            v36 = 0;
        }
    }
    while (v36 < v28) {
        MEM[v36 + v30] = MEM[v36 + v32];
        v36 += 32;
    }
    v46 = v28 + v30;
    if (0x1f & v28) {
        MEM[v46 - (0x1f & v28)] = ~(256 ** (32 - (0x1f & v28)) - 1) & MEM[v46 - (0x1f & v28)];
    }
    revert(Error(0x8c379a000000000000000000000000000000000000000000000000000000000, v26, v45));
}