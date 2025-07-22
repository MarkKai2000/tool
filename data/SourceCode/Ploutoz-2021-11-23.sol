function latestAnswer() external view override returns (uint256 _price) {
    uint112 _reserve0;
    uint112 _reserve1;
    uint32 _blockTimestampLast;

    // 获取pair的储备量和最后更新的区块时间戳
    (_reserve0, _reserve1, _blockTimestampLast) = IPancakePair(pairRef)
        .getReserves();

    _price;
    // 计算价格
    if (baseTokenIndex == 1) {
        _price = _reserve1.mul(1e18).div(_reserve0);
    } else {
        _price = _reserve0.mul(1e18).div(_reserve1);
    }
}
