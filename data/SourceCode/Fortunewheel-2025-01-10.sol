function swapProfitFees() external {
        IPancakeRouter02 router = IPancakeRouter02(pancakeRouterAddr);
        address[] memory path = new address[](2);
        uint256 totalBNBForGame;
        uint256 totalBNBForLink;
        uint256 length = casinoCount;
        uint256 BNBPPool = 0;

        // Swap each token to BNB
        for (uint256 i = 1; i <= length; ++i) {
            Casino memory casinoInfo = tokenIdToCasino[i];
            IERC20 token = IERC20(casinoInfo.tokenAddress);

            if (casinoInfo.liquidity == 0) continue;

            uint256 availableProfit = casinoInfo.profit < 0 ? 0 : uint256(casinoInfo.profit);
            if (casinoInfo.liquidity < availableProfit) {
                availableProfit = casinoInfo.liquidity;
            }

            uint256 gameFee = (availableProfit * casinoInfo.fee) / 100;
            uint256 amountForLinkFee = getTokenAmountForLink(casinoInfo.tokenAddress, linkSpent[i]);
            _updateProfitInfo(i, uint256(gameFee), availableProfit);
            casinoInfo.liquidity = tokenIdToCasino[i].liquidity;

            // If fee from the profit is not enought for link, then use liquidity
            if (gameFee < amountForLinkFee) {
                if (casinoInfo.liquidity < (amountForLinkFee - gameFee)) {
                    amountForLinkFee = gameFee + casinoInfo.liquidity;
                    tokenIdToCasino[i].liquidity = 0;
                } else {
                    tokenIdToCasino[i].liquidity -= (amountForLinkFee - gameFee);
                }
                gameFee = 0;
            } else {
                gameFee -= amountForLinkFee;
            }

            // Update Link consumption info
            _updateLinkConsumptionInfo(i, amountForLinkFee);

            if (casinoInfo.tokenAddress == address(0)) {
                totalBNBForGame += gameFee;
                totalBNBForLink += amountForLinkFee;
                continue;
            }
            if (casinoInfo.tokenAddress == BNBPAddress) {
                BNBPPool += gameFee;
                gameFee = 0;
            }

            path[0] = casinoInfo.tokenAddress;
            path[1] = wbnbAddr;

            if (gameFee + amountForLinkFee == 0) {
                continue;
            }
            token.approve(address(router), gameFee + amountForLinkFee);
            uint256[] memory swappedAmounts = router.swapExactTokensForETH(
                gameFee + amountForLinkFee,
                0,
                path,
                address(this),
                block.timestamp
            );
            totalBNBForGame += (swappedAmounts[1] * gameFee) / (gameFee + amountForLinkFee);
            totalBNBForLink += (swappedAmounts[1] * amountForLinkFee) / (gameFee + amountForLinkFee);
        }

        path[0] = wbnbAddr;
        // Convert to LINK
        if (totalBNBForLink > 0) {
            path[1] = linkTokenAddr;

            // Swap BNB into Link Token
            uint256 linkAmount = router.swapExactETHForTokens{ value: totalBNBForLink }(
                0,
                path,
                address(this),
                block.timestamp
            )[1];

            // Convert Link to ERC677 Link
            IERC20(linkTokenAddr).approve(pegSwapAddr, linkAmount);
            PegSwap(pegSwapAddr).swap(linkAmount, linkTokenAddr, link677TokenAddr);

            // Fund VRF subscription account
            LinkTokenInterface(link677TokenAddr).transferAndCall(
                coordinatorAddr,
                linkAmount,
                abi.encode(subscriptionId)
            );
            emit SuppliedLink(linkAmount);
        }

        // Swap the rest of BNB to BNBP
        if (totalBNBForGame > 0) {
            path[1] = BNBPAddress;
            BNBPPool += router.swapExactETHForTokens{ value: totalBNBForGame }(0, path, address(this), block.timestamp)[
                1
            ];
        }

        if (BNBPPool > 0) {
            // add BNBP to tokenomics pool
            IERC20(BNBPAddress).approve(potAddress, BNBPPool);
            IPotLottery(potAddress).addAdminTokenValue(BNBPPool);

            emit SuppliedBNBP(BNBPPool);
        }
    }

