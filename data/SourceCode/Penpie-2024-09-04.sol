function depositMarket(
    address _market,
    address _for,
    address _from,
    uint256 _amount
) external override nonReentrant whenNotPaused _onlyActivePoolHelper(_market) {
    Pool storage poolInfo = pools[_market];
    _harvestMarketRewards(poolInfo.market, false);

    IERC20(poolInfo.market).safeTransferFrom(_from, address(this), _amount);

    // mint the receipt to the user driectly
    IMintableERC20(poolInfo.receiptToken).mint(_for, _amount);

    emit NewMarketDeposit(
        _for,
        _market,
        _amount,
        poolInfo.receiptToken,
        _amount
    );
}

function _harvestBatchMarketRewards(
    address[] memory _markets,
    address _caller,
    uint256 _minEthToRecieve
) internal {
    uint256 harvestCallerTotalPendleReward;
    uint256 pendleBefore = IERC20(PENDLE).balanceOf(address(this));

    for (uint256 i = 0; i < _markets.length; i++) {
        if (!pools[_markets[i]].isActive) revert OnlyActivePool();
        Pool storage poolInfo = pools[_markets[i]];

        poolInfo.lastHarvestTime = block.timestamp;

        address[] memory bonusTokens = IPendleMarket(_markets[i])
            .getRewardTokens();
        uint256[] memory amountsBefore = new uint256[](bonusTokens.length);

        for (uint256 j; j < bonusTokens.length; j++) {
            if (bonusTokens[j] == NATIVE) bonusTokens[j] = address(WETH);

            amountsBefore[j] = IERC20(bonusTokens[j]).balanceOf(address(this));
        }

        IPendleMarket(_markets[i]).redeemRewards(address(this));

        for (uint256 j; j < bonusTokens.length; j++) {
            uint256 amountAfter = IERC20(bonusTokens[j]).balanceOf(
                address(this)
            );

            uint256 originalBonusBalance = amountAfter - amountsBefore[j];
            uint256 leftBonusBalance = originalBonusBalance;
            uint256 currentMarketHarvestPendleReward;

            if (originalBonusBalance == 0) continue;

            if (bonusTokens[j] == PENDLE) {
                currentMarketHarvestPendleReward =
                    (originalBonusBalance * harvestCallerPendleFee) /
                    DENOMINATOR;
                leftBonusBalance =
                    originalBonusBalance -
                    currentMarketHarvestPendleReward;
            }
            harvestCallerTotalPendleReward += currentMarketHarvestPendleReward;

            _sendRewards(
                _markets[i],
                bonusTokens[j],
                poolInfo.rewarder,
                originalBonusBalance,
                leftBonusBalance
            );
        }
    }

    uint256 pendleForMPendleFee = IERC20(PENDLE).balanceOf(address(this)) -
        pendleBefore -
        harvestCallerTotalPendleReward;
    _sendMPendleFees(pendleForMPendleFee);

    if (harvestCallerTotalPendleReward > 0) {
        IERC20(PENDLE).approve(ETHZapper, harvestCallerTotalPendleReward);

        IETHZapper(ETHZapper).swapExactTokensToETH(
            PENDLE,
            harvestCallerTotalPendleReward,
            _minEthToRecieve,
            _caller
        );
    }
}
