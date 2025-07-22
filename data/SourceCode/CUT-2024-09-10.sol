// Remove the pool
function actDealLPRemoveBehavior(
    address sender,
    address recipient,
    uint256 amount
) private {
    IActCheckContract(_transferFunDealTypeContractAddress)
        .actDealLPRemoveBehaviorTrue(sender, recipient, amount);
    // Reduce the number of effective users under the direct leadership of superiors
    if (_leaderAddressList[recipient] != address(0)) {
        if (userEffectiveDirectPushCount[_leaderAddressList[recipient]] > 0) {
            userEffectiveDirectPushCount[_leaderAddressList[recipient]] -= 1;
            ILPFutureYieldContract(_lpFutureYieldContractAddress)
                .updateLeaderTeamEffectiveNum(
                    _leaderAddressList[recipient],
                    userEffectiveDirectPushCount[_leaderAddressList[sender]]
                );
        }
    }

    _transferOrigin(sender, recipient, amount);
    // Price protection mechanism
    if (_isFirstTimeInvestmentAccount[recipient] == false) {
        if (_maxRewardsLPDynamicAmount > 0) {
            uint256 leftAmount = IActCheckContract(
                _transferFunDealTypeContractAddress
            ).valuePreservationByRemoveLP(recipient, amount);
            if (leftAmount <= amount) {
                _transferOrigin(
                    recipient,
                    _deadHoleAddress,
                    amount - leftAmount
                );
            } else {
                _balances[recipient] = _balances[recipient].add(
                    leftAmount - amount
                );
            }
            uint256 feeDealAmount = SafeMath.div(
                leftAmount * _removeLPToBlackWholeRate,
                _baseRateAmount,
                "SafeMath: division by zero"
            );
            if (_balances[recipient] >= feeDealAmount) {
                _transferOrigin(recipient, _deadHoleAddress, feeDealAmount);
            }
        }
    } else {
        _transferOrigin(recipient, _deadHoleAddress, amount);
    }
}
