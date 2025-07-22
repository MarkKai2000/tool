function receive(uint256 fromChainId, address to, uint256 nonce, uint256 volume, Signature[] memory signatures) virtual external payable {
        _chargeFee();
        require(received[fromChainId][to][nonce] == 0, 'withdrawn already');
        uint N = signatures.length;
        require(N >= Factory(factory).getConfig(_minSignatures_), 'too few signatures');
        for(uint i=0; i<N; i++) {
            for(uint j=0; j<i; j++)
                require(signatures[i].signatory != signatures[j].signatory, 'repetitive signatory');
            bytes32 structHash = keccak256(abi.encode(RECEIVE_TYPEHASH, fromChainId, to, nonce, volume, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory, "unauthorized");
            _decreaseAuthQuota(signatures[i].signatory, volume);
            emit Authorize(fromChainId, to, nonce, volume, signatory);
        }
        received[fromChainId][to][nonce] = volume;
        _receive(to, volume);
        emit Receive(fromChainId, to, nonce, volume);
    }

function decreaseAuthQuota(address signatory, uint decrement) virtual public onlyFactory returns (uint quota) {
        quota = authQuotaOf(signatory);
        if(quota < decrement)
            decrement = quota;
        return _decreaseAuthQuota(signatory, decrement);
    }


modifier updateAutoQuota(address signatory) virtual {
        uint quota = authQuotaOf(signatory);
        if(_authQuotas[signatory] != quota) {
            _authQuotas[signatory] = quota;
            lasttimeUpdateQuotaOf[signatory] = now;
        }
        _;
    }