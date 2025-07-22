function CreateMassPools(
    address _Token,
    uint64[] calldata _FinishTime,
    uint256[] calldata _StartAmount,
    address[] calldata _Owner
) external isGreaterThanZero(_Owner.length) isBelowLimit(_Owner.length) returns(uint256, uint256) {
    require(_Owner.length == _FinishTime.length, "Date Array Invalid");
    require(_Owner.length == _StartAmount.length, "Amount Array Invalid");
    TransferInToken(_Token, msg.sender, getArraySum(_StartAmount));
    uint256 firstPoolId = Index;
    for(uint i=0 ; i < _Owner.length; i++){
        CreatePool(_Token, _FinishTime[i], _StartAmount[i], _Owner[i]);
    }
    uint256 lastPoolId = SafeMath.sub(Index, 1);
    return (firstPoolId, lastPoolId);
}

function getArraySum(uint256[] calldata _array) internal pure returns(uint256) {
    uint256 sum = 0;
    for(uint i=0 ; i<_array.length ; i++){
        sum = sum + _array[i];
    }
    return sum;
}