function borrow(uint256 _amount) external nonReentrant {
    accrue();
    _borrow(msg.sender, msg.sender, _amount);
}

/// @notice Allows users to borrow ShezUSD
/// @dev emits a {Borrowed} event
/// @param _amount The amount of ShezUSD to be borrowed. Note that the user will receive less than the amount requested,
function borrowFor(
    uint256 _amount,
    address _onBehalfOf
) external nonReentrant onlyRole(LEVERAGE_ROLE) {
    accrue();
    _borrow(msg.sender, _onBehalfOf, _amount);
}

function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
}
function addCollateral(uint256 _colAmount) external nonReentrant {
    accrue();
    _addCollateral(msg.sender, msg.sender, _colAmount);
}


function _addCollateral(
    address _account,
    address _onBehalfOf,
    uint256 _colAmount
) internal override {
    if (_colAmount == 0) revert InvalidAmount(_colAmount);

    tokenContract.safeTransferFrom(_account, address(this), _colAmount);
    uint share = _colAmount;
    if (address(strategy) != address(0)) {
        tokenContract.safeApprove(address(strategy), _colAmount);
        share = strategy.deposit(_onBehalfOf, _colAmount);
    }

    Position storage position = positions[_onBehalfOf];

    if (!userIndexes.contains(_onBehalfOf)) {
        userIndexes.add(_onBehalfOf);
    }
    position.collateral += share;

    emit CollateralAdded(_onBehalfOf, _colAmount);
}

function _borrow(
    address _account,
    address _onBehalfOf,
    uint256 _amount
) internal {
    if (_amount < settings.minBorrowAmount) {
        revert MinBorrowAmount();
    }

    uint256 _totalDebtAmount = totalDebtAmount;
    if (_totalDebtAmount + _amount > settings.borrowAmountCap)
        revert DebtCapReached();

    Position storage position = positions[_onBehalfOf];
    uint256 _creditLimit = _getCreditLimit(_onBehalfOf, position.collateral);
    uint256 _debtAmount = _getDebtAmount(_onBehalfOf);
    if (_debtAmount + _amount > _creditLimit) revert InvalidAmount(_amount);

    //calculate the borrow fee
    uint256 _organizationFee = (_amount *
        settings.organizationFeeRate.numerator) /
        settings.organizationFeeRate.denominator;

    uint256 _feeAmount = _organizationFee;
    totalFeeCollected += _feeAmount;

    // update debt portion
    {
        uint256 _totalDebtPortion = totalDebtPortion;
        uint256 _plusPortion = _calculatePortion(
            _totalDebtPortion,
            _amount,
            _totalDebtAmount
        );

        totalDebtPortion = _totalDebtPortion + _plusPortion;
        position.debtPortion += _plusPortion;
        position.debtPrincipal += _amount;
        totalDebtAmount = _totalDebtAmount + _amount;
    }

    //subtract the fee from the amount borrowed
    stablecoin.mint(_account, _amount - _feeAmount);

    emit Borrowed(_onBehalfOf, _amount);
}
