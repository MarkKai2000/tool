function settlement(uint256 _index,address[] memory _userArray)public virtual onlyAdmin  returns(bool){
    for (uint i = 0; i < _userArray.length; i++) {
        if(_index == 1){
            _settlementDestoryMining(_userArray[i]);
        }else if(_index == 2){
            _settlementLpMining(_userArray[i]);
        }
    }

    return true;
}

function _settlementLpMining(address _from)internal {
    uint256 _lpTokenBalance = IERC20(gdsUsdtPair).balanceOf(_from);
    uint256 _lpTokenTotalSupply = IERC20(gdsUsdtPair).totalSupply();
    if(lastEpoch[_from] >0 && currentEpoch > lastEpoch[_from] && _lpTokenBalance>0){
        uint256 _totalRewardAmount= 0;
        for (uint i = lastEpoch[_from]; i < currentEpoch; i++) {
            _totalRewardAmount += everyEpochLpReward[i];
            _totalRewardAmount += everyDayLpMiningAmount;
        }

        uint256 _lpRewardAmount =  _totalRewardAmount*_lpTokenBalance/_lpTokenTotalSupply;
        _internalTransfer(lpPoolContract,_from,_lpRewardAmount,4);

        lastEpoch[_from] = currentEpoch;
    }

    if(lastEpoch[_from] == 0 && _lpTokenBalance >0){
        lastEpoch[_from] = currentEpoch;
    }

    if(_lpTokenBalance == 0){
        lastEpoch[_from] = 0;
    }
}
