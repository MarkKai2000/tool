function updateExchangeRate()
    external
    nonReentrant
    returns (uint256 _exchangeRate)
{
    return _updateExchangeRate();
}

function _updateExchangeRate() internal returns (uint256 _exchangeRate) {
    // Pull from storage to save gas and set default return values
    ExchangeRateInfo memory _exchangeRateInfo = exchangeRateInfo;

    // Get the latest exchange rate from the oracle
    //convert price of collateral as debt is priced in terms of collateral amount (inverse)
    _exchangeRate =
        1e36 /
        IOracle(_exchangeRateInfo.oracle).getPrices(address(collateral));

    //skip storage writes if value doesnt change
    if (_exchangeRate != _exchangeRateInfo.exchangeRate) {
        // Effects: Bookkeeping and write to storage
        _exchangeRateInfo.lastTimestamp = uint96(block.timestamp);
        _exchangeRateInfo.exchangeRate = _exchangeRate;
        exchangeRateInfo = _exchangeRateInfo;
        emit UpdateExchangeRate(_exchangeRate);
    }
}
