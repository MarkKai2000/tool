function setMerkleRoot(bytes32 _merkleRoot) public payable {
    require(msg.data.length - 4 >= 32);
    _merkleRoot = _merkleRoot;
}

function claim(address to, uint256 amount, bytes32[] proof) public payable {
    require(msg.data.length - 4 >= 96);
    require(proof <= uint64.max);
    require(4 + proof + 31 < msg.data.length);
    require(proof.length <= uint64.max);
    require(4 + proof + (proof.length << 5) + 32 <= msg.data.length);
    require(_claimStart > 0, Error("GfoxClaim: Not started"));
    require(block.timestamp >= _claimStart, Error("GfoxClaim: Not started"));
    require(amount > _claimedAmount[to], Error("GfoxClaim: Already claimed"));
    v0 = new uint256[](proof.length);
    CALLDATACOPY(v0.data, proof.data, proof.length << 5);
    v0[proof.length] = 0;
    v1 = v2 = keccak256(bytes20(to << 96), amount);
    v3 = v4 = 0;
    while (v3 < v0.length) {
        require(v3 < v0.length, Panic(50)); // access an out-of-bounds or negative index of bytesN array or slice
        v1 = v5 = 0x9c0(v0[v3], v1);
        v3 += 1;
    }
    require(v1 == _merkleRoot, Error("GfoxClaim: Invalid proof"));
    v6 = 0x718(amount);
    v7 = _SafeSub(v6, _claimedAmount[to]);
    v8 = _SafeAdd(_claimedAmount[to], v7);
    _claimedAmount[to] = v8;
    emit Claimed(to, v7, amount);
    0x7d1(v7, to, address(0x8f1cece048cade6b8a05dfa2f90ee4025f4f2662));
}
