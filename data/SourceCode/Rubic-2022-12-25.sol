function routerCallNative(
    BaseCrossChainParams calldata _params,
    bytes calldata _data
) external payable nonReentrant whenNotPaused eventEmitter(_params) {
    if (!availableRouters.contains(_params.router)) {
        revert RouterNotAvailable();
    }

    IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

    uint256 _amountIn = accrueTokenFees(
        _params.integrator,
        _info,
        accrueFixedCryptoFee(_params.integrator, _info),
        0,
        address(0)
    );

    AddressUpgradeable.functionCallWithValue(_params.router, _data, _amountIn);
}
