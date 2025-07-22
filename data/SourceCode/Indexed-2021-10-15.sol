/**
 * @dev Finds the first token which is both initialized and has a
 * desired weight above 0, then returns the address of that token
 * and the extrapolated value of the pool in terms of that token.
 *
 * The value is extrapolated by multiplying the token's
 * balance by the reciprocal of its normalized weight.
 * @return (token, extrapolatedValue)
 */
function extrapolatePoolValueFromToken()
    external
    view
    override
    _viewlock_
    returns (address /* token */, uint256 /* extrapolatedValue */)
{
    address token;
    uint256 extrapolatedValue;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
        token = _tokens[i];
        Record storage record = _records[token];
        if (record.ready && record.desiredDenorm > 0) {
            extrapolatedValue = bmul(
                record.balance,
                bdiv(_totalWeight, record.denorm)
            );
            break;
        }
    }
    require(extrapolatedValue > 0, "ERR_NONE_READY");
    return (token, extrapolatedValue);
}
