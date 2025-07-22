function transfer(
    address _to,
    uint256 _value
) external override returns (bool) {
    _transferByDefaultPartition(msg.sender, msg.sender, _to, _value, "");
    return true;
}
function _transferByDefaultPartition(
    address _operator,
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
) internal {
    _transferByPartition(
        defaultPartition,
        _operator,
        _from,
        _to,
        _value,
        _data,
        ""
    );
}
function _transferByPartition(
    bytes32 _fromPartition,
    address _operator,
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data,
    bytes memory _operatorData
) internal returns (bytes32) {
    require(_to != address(0), EC_57_INVALID_RECEIVER);

    // If the `_operator` is attempting to transfer from a different `_from`
    // address, first check that they have the requisite operator or
    // allowance permissions.
    if (_from != _operator) {
        require(
            _isOperatorForPartition(_fromPartition, _operator, _from) ||
                (_value <=
                    _allowedByPartition[_fromPartition][_from][_operator]),
            EC_53_INSUFFICIENT_ALLOWANCE
        );

        // If the sender has an allowance for the partition, that should
        // be decremented
        if (_allowedByPartition[_fromPartition][_from][_operator] >= _value) {
            _allowedByPartition[_fromPartition][_from][
                msg.sender
            ] = _allowedByPartition[_fromPartition][_from][_operator].sub(
                _value
            );
        } else {
            _allowedByPartition[_fromPartition][_from][_operator] = 0;
        }
    }

    _callPreTransferHooks(
        _fromPartition,
        _operator,
        _from,
        _to,
        _value,
        _data,
        _operatorData
    );

    require(
        _balanceOfByPartition[_from][_fromPartition] >= _value,
        EC_52_INSUFFICIENT_BALANCE
    );

    bytes32 toPartition = PartitionUtils._getDestinationPartition(
        _data,
        _fromPartition
    );

    _removeTokenFromPartition(_from, _fromPartition, _value);
    _addTokenToPartition(_to, toPartition, _value);
    _callPostTransferHooks(
        toPartition,
        _operator,
        _from,
        _to,
        _value,
        _data,
        _operatorData
    );

    emit Transfer(_from, _to, _value);
    emit TransferByPartition(
        _fromPartition,
        _operator,
        _from,
        _to,
        _value,
        _data,
        _operatorData
    );

    if (toPartition != _fromPartition) {
        emit ChangedPartition(_fromPartition, toPartition, _value);
    }

    return toPartition;
}
