function rebase(bool sync) internal whenNotRebasePaused returns (uint256) {
    if (oUSD.totalSupply() == 0) return 0;

    uint256 oldTotalSupply = oUSD.totalSupply();
    uint256 newTotalSupply = _totalValue(); // All assets in vault + all asset in strategies

    // Only ratchet upwards
    if (newTotalSupply > oldTotalSupply) {
        oUSD.changeSupply(newTotalSupply);

        if (rebaseHooksAddr != address(0)) {
            IRebaseHooks(rebaseHooksAddr).postRebase(sync);
        }
    }
}
