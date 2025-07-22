function mint(
    uint256 shares,
    address receiver
) public virtual override returns (uint256) {
    require(shares <= maxMint(receiver), "ERC4626: mint more than max");

    uint256 assets = previewMint(shares);
    _deposit(_msgSender(), receiver, assets, shares);

    return assets;
}
function _deposit(
    address _caller,
    address _receiver,
    uint256 _assets,
    uint256 _shares
) internal override checkWhitelisting {
    if (_assets < MIN_DEPOSIT) revert DepositTooLow(MIN_DEPOSIT, _assets);
    (uint256 sharesFromPool, uint256 assetsToPool) = _getmpETHFromPool(
        _shares,
        address(this)
    );
    uint256 sharesToMint = _shares - sharesFromPool;
    uint256 assetsToAdd = _assets - assetsToPool;

    if (sharesToMint > 0) _mint(address(this), sharesToMint);
    totalUnderlying += assetsToAdd;

    uint256 sharesToUser = _shares;

    if (msg.sender != liquidUnstakePool) {
        uint256 sharesToTreasury = (_shares * depositFee) / 10000;
        _transfer(address(this), treasury, sharesToTreasury);
        sharesToUser -= sharesToTreasury;
    }

    _transfer(address(this), _receiver, sharesToUser);

    emit Deposit(_caller, _receiver, _assets, _shares);
}
