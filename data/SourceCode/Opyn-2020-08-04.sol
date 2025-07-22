function exercise(
    uint256 oTokensToExercise,
    address payable[] memory vaultsToExerciseFrom
) public payable {
    for (uint256 i = 0; i < vaultsToExerciseFrom.length; i++) {
        address payable vaultOwner = vaultsToExerciseFrom[i];
        require(
            hasVault(vaultOwner),
            "Cannot exercise from a vault that doesn't exist"
        );
        Vault storage vault = vaults[vaultOwner];
        if (oTokensToExercise == 0) {
            return;
        } else if (vault.oTokensIssued >= oTokensToExercise) {
            _exercise(oTokensToExercise, vaultOwner);
            return;
        } else {
            oTokensToExercise = oTokensToExercise.sub(vault.oTokensIssued);
            _exercise(vault.oTokensIssued, vaultOwner);
        }
    }
    require(
        oTokensToExercise == 0,
        "Specified vaults have insufficient collateral"
    );
}

function _exercise(
    uint256 oTokensToExercise,
    address payable vaultToExerciseFrom
) internal {
    // 1. before exercise window: revert
    require(
        isExerciseWindow(),
        "Can't exercise outside of the exercise window"
    );

    require(hasVault(vaultToExerciseFrom), "Vault does not exist");

    Vault storage vault = vaults[vaultToExerciseFrom];
    require(oTokensToExercise > 0, "Can't exercise 0 oTokens");
    // Check correct amount of oTokens passed in)
    require(
        oTokensToExercise <= vault.oTokensIssued,
        "Can't exercise more oTokens than the owner has"
    );
    // Ensure person calling has enough oTokens
    require(balanceOf(msg.sender) >= oTokensToExercise, "Not enough oTokens");

    // 1. Check sufficient underlying
    // 1.1 update underlying balances
    uint256 amtUnderlyingToPay = underlyingRequiredToExercise(
        oTokensToExercise
    );
    vault.underlying = vault.underlying.add(amtUnderlyingToPay);

    // 2. Calculate Collateral to pay
    // 2.1 Payout enough collateral to get (strikePrice * oTokens) amount of collateral
    uint256 amtCollateralToPay = calculateCollateralToPay(
        oTokensToExercise,
        Number(1, 0)
    );

    // 2.2 Take a small fee on every exercise
    uint256 amtFee = calculateCollateralToPay(
        oTokensToExercise,
        transactionFee
    );
    totalFee = totalFee.add(amtFee);

    uint256 totalCollateralToPay = amtCollateralToPay.add(amtFee);
    require(
        totalCollateralToPay <= vault.collateral,
        "Vault underwater, can't exercise"
    );

    // 3. Update collateral + oToken balances
    vault.collateral = vault.collateral.sub(totalCollateralToPay);
    vault.oTokensIssued = vault.oTokensIssued.sub(oTokensToExercise);

    // 4. Transfer in underlying, burn oTokens + pay out collateral
    // 4.1 Transfer in underlying
    if (isETH(underlying)) {
        require(msg.value == amtUnderlyingToPay, "Incorrect msg.value");
    } else {
        require(
            underlying.transferFrom(
                msg.sender,
                address(this),
                amtUnderlyingToPay
            ),
            "Could not transfer in tokens"
        );
    }
    // 4.2 burn oTokens
    _burn(msg.sender, oTokensToExercise);

    // 4.3 Pay out collateral
    transferCollateral(msg.sender, amtCollateralToPay);

    emit Exercise(
        amtUnderlyingToPay,
        amtCollateralToPay,
        msg.sender,
        vaultToExerciseFrom
    );
}
