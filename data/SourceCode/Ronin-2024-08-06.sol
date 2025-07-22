function initializeV3() external reinitializer(3) {
    IBridgeManager mainchainBridgeManager = IBridgeManager(
        getContract(ContractType.BRIDGE_MANAGER)
    );
    (
        ,
        address[] memory operators,
        uint96[] memory weights
    ) = mainchainBridgeManager.getFullBridgeOperatorInfos();

    uint96 totalWeight;
    for (uint i; i < operators.length; i++) {
        _operatorWeight[operators[i]] = weights[i];
        totalWeight += weights[i];
    }
    _totalOperatorWeight = totalWeight;
}

function initializeV4(
    address payable wethUnwrapper_
) external reinitializer(4) {
    wethUnwrapper = WethUnwrapper(wethUnwrapper_);
}
