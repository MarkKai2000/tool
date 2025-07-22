function withdrawExactAmount(
    uint256 _nftId,
    address _poolToken,
    uint256 _withdrawAmount
) external syncPool(_poolToken) returns (uint256) {
    uint256 withdrawShares = _preparationsWithdraw(
        _nftId,
        msg.sender,
        _poolToken,
        _withdrawAmount
    );

    _coreWithdrawToken({
        _caller: msg.sender,
        _nftId: _nftId,
        _poolToken: _poolToken,
        _amount: _withdrawAmount,
        _shares: withdrawShares,
        _onBehalf: false
    });

    _safeTransfer(_poolToken, msg.sender, _withdrawAmount);

    return withdrawShares;
}

function _preparationsWithdraw(
    uint256 _nftId,
    address _caller,
    address _poolToken,
    uint256 _amount
) internal view returns (uint256) {
    _checkOwnerPosition(_nftId, _caller);

    return
        calculateLendingShares({
            _poolToken: _poolToken,
            _amount: _amount,
            _maxSharePrice: true
        });
}

function calculateLendingShares(
    address _poolToken,
    uint256 _amount,
    bool _maxSharePrice
) public view returns (uint256) {
    return
        _calculateShares(
            lendingPoolData[_poolToken].totalDepositShares * _amount,
            lendingPoolData[_poolToken].pseudoTotalPool,
            _maxSharePrice
        );
}

function _calculateShares(
    uint256 _product,
    uint256 _pseudo,
    bool _maxSharePrice
) private pure returns (uint256) {
    return
        _maxSharePrice == true
            ? _product % _pseudo == 0
                ? _product / _pseudo
                : _product / _pseudo + 1
            : _product / _pseudo;
}
