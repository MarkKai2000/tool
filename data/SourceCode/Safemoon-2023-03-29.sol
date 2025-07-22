function burn(address from, uint256 amount) public {
    _tokenTransfer(from, bridgeBurnAddress, amount, 0, false);
}

function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    uint256 tierIndex,
    bool takeFee
) private {
    if (!takeFee) removeAllFee();

    if (!_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferStandard(sender, recipient, amount, tierIndex);
    } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferFromExcluded(sender, recipient, amount, tierIndex);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        _transferToExcluded(sender, recipient, amount, tierIndex);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
        _transferBothExcluded(sender, recipient, amount, tierIndex);
    }

    if (!takeFee) restoreAllFee();
}