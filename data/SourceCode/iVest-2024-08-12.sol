function _transfer(address from, address to, uint256 value) internal virtual {
    if (from == address(0)) {
        revert ERC20InvalidSender(address(0));
    }
    if (to == address(0)) {
        revert ERC20InvalidReceiver(address(0));
    }
    _update(from, to, value);
}

function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");

    require(
        amount >= 10000,
        "iVest: Transfer amount must be at least 1 iVest (or 10000 including decimals)"
    );

    require(
        _MASTER_TRANSFERS_ENABLED,
        "iVest: Transfers are halted temporarily: _MASTER_TRANSFERS_ENABLED is DISABLED"
    );

    //Transfers directly to the vestingpool will be considered a vesting reward donation
    if (to == _vestingpool) {
        __MakeDonation(from, amount, 1);
    }

    //Transfers directly to the burn address will be considered a Burn donation
    if (to == address(0)) {
        __MakeDonation(from, amount, 3);
    }

    //Prevent ordinary wallets from sending tokens spuriously...
    if (!_isExcludedFromFee[from]) {
        require(
            to != owner,
            "iVest: This wallet cannont accept iVest from ordinary wallets."
        );
        require(
            to != address(this),
            "iVest: This wallet cannont accept iVest from ordinary wallets."
        );

        //If an ordinary wallet transfers to the DAO, award them karma and take no fee.
        if (to == DAOwallet) {
            uint256 kAmount = amount / 10000;
            _tokenTransfer(from, to, amount, false);
            karma[from] += kAmount; //Increases karma of the donating account equal to the tokens donated.
            emit AwardKarma(from, kAmount); //Emit an event
            emit NewDonation(from, "DAO Donation", kAmount);
        }
    }

    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
        takeFee = false;
    }

    //IS A SELL FROM A REGULAR WALLET
    if ((to == _liquiditypool) && !_isExcludedFromFee[from]) {
        //check for whale
        if (tokenFromReflection(_rOwned[from]) >= _WhaleThreshold) {
            uint256 whaleFee = ((amount * (_whaleDonationFee)) / (100));
            __MakeDonation(from, whaleFee, 4);
        }
    }

    //IS A BUY FROM A REGULAR WALLET
    if (from == _liquiditypool) {
        bool isWhale = false;
        if (tokenFromReflection(_rOwned[to]) >= _WhaleThreshold) {
            isWhale = true;
        }

        if (_isExcludedFromFee[to]) {
            isWhale = false;
            takeFee = false;
            removeAllFee();
        }

        if (to == LiquidityShield && address(msg.sender) == LiquidityShield) {
            takeFee = false;
            isWhale = false;
            removeAllFee();
        }

        _transferFromLP(from, to, amount, isWhale);
        if (!takeFee) {
            restoreAllFee();
        }
        return;
    }

    //not exculded and sending tokens to the LP is a sell
    if (!_isExcludedFromFee[from] && to == _liquiditypool) {
        takeFee = true;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
}
