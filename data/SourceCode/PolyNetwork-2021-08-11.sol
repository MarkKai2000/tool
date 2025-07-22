function crossChain(
    uint64 toChainId,
    bytes calldata toContract,
    bytes calldata method,
    bytes calldata txData
) external whenNotPaused returns (bool) {
    // Load Ethereum cross chain data contract
    IEthCrossChainData eccd = IEthCrossChainData(
        EthCrossChainDataContractAddress
    );

    // To help differentiate two txx, the ethTxHashIndex is increasing automatically
    uint256 txhashIndex = eccd.getEthTxHashIndex();

    // Convert the uint256 into bytes
    bytes memory paramTxHash = Utils.uint256ToBytes(txhashIndex);

    // Construct the makeTxParam, and put the hash info storage, to help provide proof of tx existence
    bytes memory rawParam = abi.encodePacked(
        ZeroCopySink.WriteVarBytes(paramTxHash),
        ZeroCopySink.WriteVarBytes(
            abi.encodePacked(
                sha256(abi.encodePacked(address(this), paramTxHash))
            )
        ),
        ZeroCopySink.WriteVarBytes(Utils.addressToBytes(msg.sender)),
        ZeroCopySink.WriteInt64(toChainId),
        ZeroCopySink.WriteVarBytes(toContract),
        ZeroCopySink.WriteVarBytes(method),
        ZeroCopySink.WriteVarBytes(txData)
    );

    // Must save it in the storage to be included in the proof to be verified.
    require(
        eccd.putEthTxHash(keccak256(rawParam)),
        "Save ethTxHash by index to Data contract failed!"
    );

    // Fire the cross chain event denoting there is a cross chain request from Ethereum network to other public chains through Poly chain network
    emit CrossChainEvent(
        tx.origin,
        paramTxHash,
        msg.sender,
        toChainId,
        toContract,
        rawParam
    );

    return true;
}
