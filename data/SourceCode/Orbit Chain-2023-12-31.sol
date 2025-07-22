function withdraw(
    address hubContract,
    string memory fromChain,
    bytes memory fromAddr,
    bytes memory toAddr,
    bytes memory token,
    bytes32[] memory bytes32s,
    uint[] memory uints,
    uint8[] memory v,
    bytes32[] memory r,
    bytes32[] memory s
) public onlyActivated {
    require(bytes32s.length >= 1);
    require(bytes32s[0] == sha256(abi.encodePacked(hubContract, chain, address(this))));
    require(uints.length >= 2);
    require(isValidChain[getChainId(fromChain)]);

    bytes32 whash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints));

    require(!isUsedWithdrawal[whash]);
    isUsedWithdrawal[whash] = true;

    uint validatorCount = _validate(whash, v, r, s);
    require(validatorCount >= required);

    address payable _toAddr = bytesToAddress(toAddr);
    address tokenAddress = bytesToAddress(token);
    if(tokenAddress == address(0)){
        if(!_toAddr.send(uints[0])) revert();
    }else{
        if(tokenAddress == tetherAddress){
            TIERC20(tokenAddress).transfer(_toAddr, uints[0]);
        }
        else{
            if(!IERC20(tokenAddress).transfer(_toAddr, uints[0])) revert();
        }
    }

    emit Withdraw(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints);
}

function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
    uint validatorCount = 0;
    address[] memory vaList = new address[](owners.length);

    uint i=0;
    uint j=0;

    for(i; i<v.length; i++){
        address va = ecrecover(whash,v[i],r[i],s[i]);
        if(isOwner[va]){
            for(j=0; j<validatorCount; j++){
                require(vaList[j] != va);
            }

            vaList[validatorCount] = va;
            validatorCount += 1;
        }
    }

    return validatorCount;
}