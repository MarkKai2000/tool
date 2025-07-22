function collateralizedMint(
    PoolParams calldata poolParams,
    bytes32 orderHash,
    uint256 shares,
    address longRecipient,
    address shortRecipient
) external {
    _collateralizedMint(
        poolParams,
        orderHash,
        shares,
        msg.sender,
        longRecipient,
        shortRecipient
    );
}

function _collateralizedMint(
    PoolParams calldata poolParams,
    bytes32 orderHash,
    uint256 shares,
    address payer,
    address longRecipient,
    address shortRecipient
) internal {
    bytes32 poolHash = hashPool(poolParams);

    if (sPoolState[poolHash].actualEndTimestamp != 0) {
        revert SilicaPools__PoolAlreadyEnded(poolHash);
    }

    ISilicaIndex index = ISilicaIndex(poolParams.index);
    ISilicaPools.PoolState storage sState = sPoolState[poolHash];

    uint256 collateral = PoolMaths.collateral(
        true,
        poolParams.floor,
        poolParams.cap,
        shares,
        index.decimals()
    );

    sState.collateralMinted += uint128(collateral);

    SafeERC20.safeTransferFrom(
        IERC20(poolParams.payoutToken),
        payer,
        address(this),
        collateral
    );

    if (longRecipient == address(0)) {
        longRecipient = msg.sender;
    }
    if (shortRecipient == address(0)) {
        shortRecipient = msg.sender;
    }

    sState.sharesMinted += uint128(shares);

    _mint(longRecipient, toLongTokenId(poolHash), shares, "");
    _mint(shortRecipient, toShortTokenId(poolHash), shares, "");

    emit SilicaPools__CollateralizedMint(
        poolHash,
        orderHash,
        shortRecipient,
        longRecipient,
        payer,
        poolParams.payoutToken,
        shares,
        collateral
    );
}

function redeemShort(PoolParams calldata shortParams) public {
    bytes32 poolHash = hashPool(shortParams);
    PoolState storage sState = sPoolState[poolHash];

    if (sState.actualEndTimestamp == 0) {
        revert SilicaPools__PoolNotEnded(poolHash);
    }

    uint256 shortTokenId = toShortTokenId(poolHash);
    uint256 shortSharesBalance = balanceOf(msg.sender, shortTokenId);

    // Short payouts pay ((cap - balanceChangePerShare) * collateralMinted) / ((cap - floor)) * shortSharesBalance) / totalSharesMinted)
    uint256 payout = PoolMaths.shortPayout(
        shortParams,
        sState,
        shortSharesBalance
    );

    _burn(msg.sender, shortTokenId, shortSharesBalance);

    SafeERC20.safeTransfer(IERC20(shortParams.payoutToken), msg.sender, payout);

    emit SilicaPools__SharesRedeemed(
        poolHash,
        msg.sender,
        shortParams.payoutToken,
        shortTokenId,
        shortSharesBalance,
        payout
    );
}

function shortPayout(
    ISilicaPools.PoolParams memory shortParams,
    ISilicaPools.PoolState memory sState,
    uint256 shortSharesBalance
) internal pure returns (uint256 payout) {
    // Short payouts pay (cap - balanceChangePerShare) * collateralMinted / (cap - floor) * shortSharesBalance / totalSharesMinted
    payout =
        (((uint256(shortParams.cap - sState.balanceChangePerShare) *
            uint256(sState.collateralMinted)) /
            uint256(shortParams.cap - shortParams.floor)) *
            uint256(shortSharesBalance)) /
        uint256(sState.sharesMinted);
}
