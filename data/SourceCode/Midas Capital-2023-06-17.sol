/**
 * @notice User redeems cTokens in exchange for the underlying asset
 * @dev Assumes interest has already been accrued up to the current block
 * @param redeemer The address of the account which is redeeming the tokens
 * @param redeemTokensIn The number of cTokens to redeem into underlying
 *    (only one of redeemTokensIn or redeemAmountIn may be non-zero)
 * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens
 *    (only one of redeemTokensIn or redeemAmountIn may be non-zero)
 * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
 */
function redeemFresh(address redeemer, uint256 redeemTokensIn, uint256 redeemAmountIn) internal returns (uint256) {
  require(redeemTokensIn == 0 || redeemAmountIn == 0, "!redeemTokensInorOut!=0");

  RedeemLocalVars memory vars;

  /* exchangeRate = invoke Exchange Rate Stored() */
  (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
  if (vars.mathErr != MathError.NO_ERROR) {
    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
  }

  if (redeemAmountIn == type(uint256).max) {
    redeemAmountIn = comptroller.getMaxRedeemOrBorrow(redeemer, address(this), false);
  }

  /* If redeemTokensIn > 0: */
  if (redeemTokensIn > 0) {
    /*
      * We calculate the exchange rate and the amount of underlying to be redeemed:
      *  redeemTokens = redeemTokensIn
      *  redeemAmount = redeemTokensIn x exchangeRateCurrent
      */
    vars.redeemTokens = redeemTokensIn;

    (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint256(vars.mathErr));
    }
  } else {
    /*
      * We get the current exchange rate and calculate the amount to be redeemed:
      *  redeemTokens = redeemAmountIn / exchangeRate
      *  redeemAmount = redeemAmountIn
      */

    (vars.mathErr, vars.redeemTokens) =
      divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    vars.redeemAmount = redeemAmountIn;
  }

  /* Fail if redeem not allowed */
  uint256 allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
  if (allowed != 0) {
    return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
  }

  /* Verify market's block number equals current block number */
  if (accrualBlockNumber != getBlockNumber()) {
    return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
  }

  /*
    * We calculate the new total supply and redeemer balance, checking for underflow:
    *  totalSupplyNew = totalSupply - redeemTokens
    *  accountTokensNew = accountTokens[redeemer] - redeemTokens
    */
  (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
  if (vars.mathErr != MathError.NO_ERROR) {
    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint256(vars.mathErr));
  }

  (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
  if (vars.mathErr != MathError.NO_ERROR) {
    return
      failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
  }

  /* Fail gracefully if protocol has insufficient cash */
  if (getCashPrior() < vars.redeemAmount) {
    return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
  }


  totalSupply = vars.totalSupplyNew;
  accountTokens[redeemer] = vars.accountTokensNew;

  /*
    * We invoke doTransferOut for the redeemer and the redeemAmount.
    *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
    *  On success, the cToken has redeemAmount less of cash.
    *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
    */
  doTransferOut(redeemer, vars.redeemAmount);

  /* We emit a Transfer event, and a Redeem event */
  emit Transfer(redeemer, address(this), vars.redeemTokens);
  emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

  /* We call the defense hook */
  comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

  return uint256(Error.NO_ERROR);
}