function redeemUnderlying(uint redeemAmount) external returns (uint) {
    return redeemUnderlyingInternal(redeemAmount);
}
function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant returns (uint) {
    uint error = accrueInterest();
    if (error != uint(Error.NO_ERROR)) {
        // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
        return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
    }
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(msg.sender, 0, redeemAmount);
}

function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
    require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

    RedeemLocalVars memory vars;

    /* exchangeRate = invoke Exchange Rate Stored() */
    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
        return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
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
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
        }
    } else {
        /*
            * We get the current exchange rate and calculate the amount to be redeemed:
            *  redeemTokens = redeemAmountIn / exchangeRate
            *  redeemAmount = redeemAmountIn
            */

        (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
        }

        vars.redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
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
        return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
    }

    (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
        return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (getCashPrior() < vars.redeemAmount) {
        return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[redeemer] = vars.accountTokensNew;

    /*
        * We invoke doTransferOut for the redeemer and the redeemAmount.
        *  Note: The oToken must handle variations between ERC-20 and ETH underlying.
        *  On success, the oToken has redeemAmount less of cash.
        *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        */
    doTransferOut(redeemer, vars.redeemAmount);

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), vars.redeemTokens);
    emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

    /* We call the defense hook */
    comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

    return uint(Error.NO_ERROR);
}
function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
        return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
}
function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
    (MathError err0, uint numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
        return (err0, Exp({mantissa: 0}));
    }
    return getExp(numerator, divisor.mantissa);
}
function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
    (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
        return (err0, Exp({mantissa: 0}));
    }

    (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
        return (err1, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: rational}));
}
function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (b == 0) {
        return (MathError.DIVISION_BY_ZERO, 0);
    }
    return (MathError.NO_ERROR, a / b);
}