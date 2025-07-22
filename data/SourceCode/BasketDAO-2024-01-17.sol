function zapToBMI(
    address _from,
    uint256 _amount,
    address _fromUnderlying,
    uint256 _fromUnderlyingAmount,
    uint256 _minBMIRecv,
    address[] memory _bmiConstituents,
    uint256[] memory _bmiConstituentsWeightings,
    address _aggregator,
    bytes memory _aggregatorData,
    bool refundDust
) public returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < _bmiConstituentsWeightings.length; i++) {
        sum = sum.add(_bmiConstituentsWeightings[i]);
    } // Sum should be between 0.999 and 1.000
    assert(sum <= 1e18);
    assert(sum >= 999e15);
    // Transfer to contract
    IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
    // Primitive
    if (_isBare(_from)) {
        _primitiveToBMI(
            _from,
            _amount,
            _bmiConstituents,
            _bmiConstituentsWeightings,
            _aggregator,
            _aggregatorData
        );
    }
    // Yearn (primitive)
    else if (_isYearn(_from)) {
        IYearn(_from).withdraw();
        _primitiveToBMI(
            _fromUnderlying,
            _fromUnderlyingAmount,
            _bmiConstituents,
            _bmiConstituentsWeightings,
            _aggregator,
            _aggregatorData
        );
    }
    // Yearn (primitive)
    else if (_isYearnCRV(_from)) {
        IYearn(_from).withdraw();
        address crvToken = IYearn(_from).token();
        _crvToPrimitive(crvToken, IERC20(crvToken).balanceOf(address(this)));
        _primitiveToBMI(
            USDC,
            IERC20(USDC).balanceOf(address(this)),
            _bmiConstituents,
            _bmiConstituentsWeightings,
            address(0),
            ""
        );
    }
    // Compound
    else if (_isCompound(_from)) {
        require(ICToken(_from).redeem(_amount) == 0, "!ctoken-redeem");
        _primitiveToBMI(
            _fromUnderlying,
            _fromUnderlyingAmount,
            _bmiConstituents,
            _bmiConstituentsWeightings,
            _aggregator,
            _aggregatorData
        );
    }
    // Aave
    else if (_isAave(_from)) {
        IERC20(_from).safeApprove(AAVE_LENDING_POOL_V2, 0);
        IERC20(_from).safeApprove(AAVE_LENDING_POOL_V2, _amount);
        ILendingPoolV2(AAVE_LENDING_POOL_V2).withdraw(
            _fromUnderlying,
            type(uint256).max,
            address(this)
        );
        _primitiveToBMI(
            _fromUnderlying,
            _fromUnderlyingAmount,
            _bmiConstituents,
            _bmiConstituentsWeightings,
            _aggregator,
            _aggregatorData
        );
    }
    // Curve
    else {
        _crvToPrimitive(_from, _amount);
        _primitiveToBMI(
            USDC,
            IERC20(USDC).balanceOf(address(this)),
            _bmiConstituents,
            _bmiConstituentsWeightings,
            address(0),
            ""
        );
    }
    // Checks
    uint256 _bmiBal = IERC20(BMI).balanceOf(address(this));
    require(_bmiBal >= _minBMIRecv, "!min-mint");
    IERC20(BMI).safeTransfer(msg.sender, _bmiBal);
    // Convert back dust to USDC and refund remaining USDC to usd
    if (refundDust) {
        for (uint256 i = 0; i < _bmiConstituents.length; i++) {
            _fromBMIConstituentToUSDC(
                _bmiConstituents[i],
                IERC20(_bmiConstituents[i]).balanceOf(address(this))
            );
        }
        IERC20(USDC).safeTransfer(
            msg.sender,
            IERC20(USDC).balanceOf(address(this))
        );
    }
    return _bmiBal;
}
