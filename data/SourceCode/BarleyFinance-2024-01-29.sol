function flash(
    address _recipient,
    address _token,
    uint256 _amount,
    bytes calldata _data
) external override {
    address _rewards = StakingPoolToken(lpStakingPool).poolRewards();
    IERC20(DAI).safeTransferFrom(
        _msgSender(),
        _rewards,
        FLASH_FEE_DAI * 10 ** IERC20Metadata(DAI).decimals()
    );
    uint256 _balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(_recipient, _amount);
    IFlashLoanRecipient(_recipient).callback(_data);
    require(IERC20(_token).balanceOf(address(this)) >= _balance, "FLASHAFTER");
    emit FlashLoan(_msgSender(), _recipient, _token, _amount);
}
function bond(address _token, uint256 _amount) external override noSwap {
    require(_isTokenInIndex[_token], "INVALIDTOKEN");
    uint256 _tokenIdx = _fundTokenIdx[_token];
    uint256 _tokensMinted = (_amount * FixedPoint96.Q96 * 10 ** decimals()) /
        indexTokens[_tokenIdx].q1;
    uint256 _feeTokens = _isFirstIn() ? 0 : (_tokensMinted * BOND_FEE) / 10000;
    _mint(_msgSender(), _tokensMinted - _feeTokens);
    if (_feeTokens > 0) {
        _mint(address(this), _feeTokens);
    }
    for (uint256 _i; _i < indexTokens.length; _i++) {
        uint256 _transferAmount = _i == _tokenIdx
            ? _amount
            : (_amount *
                indexTokens[_i].weighting *
                10 ** IERC20Metadata(indexTokens[_i].token).decimals()) /
                indexTokens[_tokenIdx].weighting /
                10 ** IERC20Metadata(_token).decimals();
        _transferAndValidate(
            IERC20(indexTokens[_i].token),
            _msgSender(),
            _transferAmount
        );
    }
    emit Bond(_msgSender(), _token, _amount, _tokensMinted);
}
function debond(
    uint256 _amount,
    address[] memory,
    uint8[] memory
) external override noSwap {
    uint256 _amountAfterFee = _isLastOut(_amount)
        ? _amount
        : (_amount * (10000 - DEBOND_FEE)) / 10000;
    uint256 _percAfterFeeX96 = (_amountAfterFee * FixedPoint96.Q96) /
        totalSupply();
    _transfer(_msgSender(), address(this), _amount);
    _burn(address(this), _amountAfterFee);
    for (uint256 _i; _i < indexTokens.length; _i++) {
        uint256 _tokenSupply = IERC20(indexTokens[_i].token).balanceOf(
            address(this)
        );
        uint256 _debondAmount = (_tokenSupply * _percAfterFeeX96) /
            FixedPoint96.Q96;
        IERC20(indexTokens[_i].token).safeTransfer(_msgSender(), _debondAmount);
        require(
            IERC20(indexTokens[_i].token).balanceOf(address(this)) >=
                _tokenSupply - _debondAmount,
            "HEAVY"
        );
    }
    emit Debond(_msgSender(), _amount);
}
