@payable
@external
@nonreentrant('lock')
def add_liquidity(
    _amounts: uint256[N_COINS],
    _min_mint_amount: uint256,
    _receiver: address = msg.sender
) -> uint256:
    """
    @notice Deposit coins into the pool
    @param _amounts List of amounts of coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _receiver Address that owns the minted LP tokens
    @return Amount of LP tokens received by depositing
    """
    amp: uint256 = self._A()
    old_balances: uint256[N_COINS] = self.balances
    rates: uint256[N_COINS] = self.rate_multipliers

    # Initial invariant
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)

    total_supply: uint256 = self.totalSupply
    new_balances: uint256[N_COINS] = old_balances
    for i in range(N_COINS):
        amount: uint256 = _amounts[i]
        if total_supply == 0:
            assert amount > 0  # dev: initial deposit requires all coins
        new_balances[i] += amount

    # Invariant after change
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    mint_amount: uint256 = 0
    if total_supply > 0:
        # Only account for fees if we are not the first to deposit
        base_fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            new_balance: uint256 = new_balances[i]
            if ideal_balance > new_balance:
                difference = ideal_balance - new_balance
            else:
                difference = new_balance - ideal_balance
            fees[i] = base_fee * difference / FEE_DENOMINATOR
            self.balances[i] = new_balance - (fees[i] * ADMIN_FEE / FEE_DENOMINATOR)
            new_balances[i] -= fees[i]
        D2: uint256 = self.get_D_mem(rates, new_balances, amp)
        mint_amount = total_supply * (D2 - D0) / D0
    else:
        self.balances = new_balances
        mint_amount = D1  # Take the dust if there was any

    assert mint_amount >= _min_mint_amount, "Slippage screwed you"

    # Take coins from the sender
    assert msg.value == _amounts[0]
    if _amounts[1] > 0:
        response: Bytes[32] = raw_call(
            self.coins[1],
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(msg.sender, bytes32),
                convert(self, bytes32),
                convert(_amounts[1], bytes32),
            ),
            max_outsize=32,
        )
        if len(response) > 0:
            assert convert(response, bool)  # dev: failed transfer
        # end "safeTransferFrom"

    # Mint pool tokens
    total_supply += mint_amount
    self.balanceOf[_receiver] += mint_amount
    self.totalSupply = total_supply
    log Transfer(ZERO_ADDRESS, _receiver, mint_amount)

    log AddLiquidity(msg.sender, _amounts, fees, D1, total_supply)

    return mint_amount