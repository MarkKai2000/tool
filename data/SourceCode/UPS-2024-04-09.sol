function transferFrom(
    address from,
    address to,
    uint256 value
) public virtual returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, value);
    _transfer(from, to, value);
    return true;
}

function _transfer(address from, address to, uint256 value) internal {
    if (from == address(0)) {
        revert ERC20InvalidSender(address(0));
    }
    if (to == address(0)) {
        revert ERC20InvalidReceiver(address(0));
    }
    _update(from, to, value);
}

function _update(
    address from,
    address to,
    uint256 amount
) internal virtual override {
    if (
        inSwapAndLiquify ||
        whiteMap[from] ||
        whiteMap[to] ||
        !(from == pairAddress || to == pairAddress)
    ) {
        super._update(from, to, amount);
    } else if (from == pairAddress) {
        require(canBuy || getPrice() > 5e14, "can not trade");
        if (!canBuy) {
            canBuy = true;
        }
        super._update(from, to, amount);
    } else if (to == pairAddress) {
        uint256 fee = (amount * 5) / 100;
        if (!inSwapAndLiquify) {
            _swapBurn(amount - fee);
        }
        if (nodeList.length > 0) {
            uint256 every = fee / nodeList.length;
            for (uint256 i = 0; i < nodeList.length; i++) {
                super._update(from, nodeList[i], every);
            }
        } else {
            _burn(from, fee);
        }
        super._update(from, to, amount - fee);
    }
}
