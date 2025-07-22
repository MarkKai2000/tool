function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
        sender,
        _msgSender(),
        _allowances[sender][_msgSender()].sub(
            amount,
            "ERC20: transfer amount exceeds allowance"
        )
    );
    return true;
}
function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    require(!_blacklist[from], "blacklists");
    require(balanceOf(from) >= amount, "error");

    if (amount == 0) {
        super._transfer(from, to, 0);
        return;
    }

    UserInfo storage userInfo;

    uint256 addLPLiquidity;
    bool isAddLP;
    if (to == uniswapV2Pair && address(uniswapV2Router) == msg.sender) {
        addLPLiquidity = _isAddLiquidity(amount);
        if (addLPLiquidity > 0) {
            isAddLP = true;
            userInfo = _userInfo[from];
            userInfo.lpAmount += addLPLiquidity;
            try
                lpDividendTracker.setBalance(payable(from), userInfo.lpAmount)
            {} catch {}
        }
    }

    uint256 removeLPLiquidity;
    if (from == uniswapV2Pair) {
        removeLPLiquidity = _strictCheckBuy(amount);
        if (removeLPLiquidity > 0) {
            if (!_isExcludedFromFees[to]) {
                require(_userInfo[to].lpAmount >= removeLPLiquidity);
            }
            uint256 blp = IUniswapV2Pair(uniswapV2Pair).balanceOf(to);
            _userInfo[to].lpAmount = blp;
            try lpDividendTracker.setBalance(payable(to), blp) {} catch {}
        }
    }

    if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
        if (
            !isAddLP &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            uint256 sellAmount = 0;
            if (block.timestamp <= startSwapTime + 30 days) {
                sellAmount = (amount * 12) / 100;
            } else if (block.timestamp <= startSwapTime + 60 days) {
                sellAmount = (amount * 4) / 100;
            } else if (block.timestamp <= startSwapTime + 90 days) {
                sellAmount = (amount * 6) / 100;
            } else if (block.timestamp <= startSwapTime + 120 days) {
                sellAmount = (amount * 8) / 100;
            }

            if (sellAmount > 0 && balanceOf(address(this)) >= sellAmount) {
                swapAndSendDividends(sellAmount);
                burnPoolToken(sellAmount);
            }
            uint256 contractTokenBalance = balanceOf(taxAddress);
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            if (canSwap) {
                swapAndAddLiqidity(contractTokenBalance);
            }
            swapping = false;
        }
        require(block.timestamp >= startSwapTime, "not start");

        uint256 fees;
        if (automatedMarketMakerPairs[from]) {
            fees = amount.mul(buyFees).div(1000);
            if (
                block.timestamp < startSwapTime + 3 &&
                !automatedMarketMakerPairs[to]
            ) {
                _blacklist[to] = true;
            }
            if (block.timestamp < startSwapTime + 5 minutes) {
                require(amount <= txLimit, "txlimit");
            }
        } else if (automatedMarketMakerPairs[to]) {
            if (isAddLP) {
                fees = amount.mul(35).div(1000);
            } else {
                fees = amount.mul(sellFees).div(1000);
            }
        }
        super._transfer(from, taxAddress, fees);
        amount -= fees;
    }
    super._transfer(from, to, amount);

    if (!swapping) {
        uint256 gas = gasForProcessing;
        try lpDividendTracker.process(gas) returns (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) {
            emit ProcessedDividendTracker(
                iterations,
                claims,
                lastProcessedIndex,
                true,
                gas,
                tx.origin
            );
        } catch {}
    }
}

function swapAndSendDividends(uint256 tokenAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _baseToken;
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(_tokenDistributor),
        block.timestamp
    );
    uint256 totalAmount = IERC20(_baseToken).balanceOf(
        address(_tokenDistributor)
    );
    IERC20(_baseToken).transferFrom(
        address(_tokenDistributor),
        address(lpDividendTracker),
        totalAmount
    );
    try lpDividendTracker.distributeDividends(totalAmount) {} catch {}
}
