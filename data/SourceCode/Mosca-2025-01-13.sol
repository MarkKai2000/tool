function join(
    uint256 amount,
    uint256 _refCode,
    uint8 fiat,
    bool enterpriseJoin
) external nonReentrant {
    User storage user = users[msg.sender];
    uint256 diff = user.balance > 127 * 10 ** 18
        ? user.balance - 127 * 10 ** 18
        : 0;
    uint256 tax_remainder;

    uint256 baseAmount = ((amount + diff) * 1000) / 1015;

    if (enterpriseJoin) {
        if (refByAddr[msg.sender] == 0) {
            require(
                amount >= (ENTERPRISE_JOIN_FEE * 3) + (JOIN_FEE * 3),
                "Insufficient amount sent to join enterprise"
            );
            if (fiat == 1) {
                require(
                    usdt.transferFrom(
                        msg.sender,
                        address(this),
                        amount - (ENTERPRISE_TAX * 3)
                    ),
                    "Transfer failed"
                );
                require(
                    usdt.transferFrom(
                        msg.sender,
                        feeReceiver,
                        ENTERPRISE_TAX * 3
                    ),
                    "Transfer tax failed"
                );
            } else {
                require(
                    usdc.transferFrom(
                        msg.sender,
                        address(this),
                        amount - (ENTERPRISE_TAX * 3)
                    ),
                    "Transfer failed"
                );
                require(
                    usdc.transferFrom(
                        msg.sender,
                        feeReceiver,
                        ENTERPRISE_TAX * 3
                    ),
                    "Transfer tax failed"
                );
            }

            emit AdminFeesSent(
                owner,
                block.timestamp,
                ENTERPRISE_TAX * 3,
                fiat
            );
        } else {
            require(
                amount + diff >= (ENTERPRISE_JOIN_FEE * 3),
                "Insufficient amount to upgrade to enterprise"
            );
            if (diff < ENTERPRISE_TAX * 3) {
                tax_remainder = (ENTERPRISE_TAX * 3) - diff;
                adminBalance += (ENTERPRISE_TAX * 3) - diff;
                user.balance -= diff;
                diff = 0;

                if (fiat == 1) {
                    require(
                        usdt.transferFrom(
                            msg.sender,
                            feeReceiver,
                            tax_remainder
                        ),
                        "Transfer failed"
                    );
                } else {
                    require(
                        usdc.transferFrom(
                            msg.sender,
                            feeReceiver,
                            tax_remainder
                        ),
                        "Transfer failed"
                    );
                }

                emit AdminFeesSent(owner, block.timestamp, tax_remainder, fiat);
            } else {
                adminBalance += ENTERPRISE_TAX * 3;
                diff -= ENTERPRISE_TAX * 3;
                user.balance -= ENTERPRISE_TAX * 3;
                if (diff > ENTERPRISE_JOIN_FEE * 3) {
                    user.balance -= (ENTERPRISE_JOIN_FEE * 3);
                } else {
                    user.balance -= diff;
                }
            }

            if (amount > 0) {
                if (fiat == 1) {
                    require(
                        usdt.transferFrom(
                            msg.sender,
                            address(this),
                            amount - tax_remainder
                        ),
                        "Transfer failed"
                    );
                } else {
                    require(
                        usdc.transferFrom(
                            msg.sender,
                            address(this),
                            amount - tax_remainder
                        ),
                        "Transfer failed"
                    );
                }
            }
        }
        user.enterprise = true;
    } else {
        require(amount >= JOIN_FEE, "Insufficient amount sent");

        if (fiat == 1) {
            require(
                usdt.transferFrom(
                    msg.sender,
                    address(this),
                    amount - (TAX * 3)
                ),
                "Transfer failed"
            );
            require(
                usdt.transferFrom(msg.sender, feeReceiver, TAX * 3),
                "Transfer failed"
            );
        } else {
            require(
                usdc.transferFrom(
                    msg.sender,
                    address(this),
                    amount - (TAX * 3)
                ),
                "Transfer failed"
            );
            require(
                usdc.transferFrom(msg.sender, feeReceiver, TAX * 3),
                "Transfer failed"
            );
        }

        emit AdminFeesSent(owner, block.timestamp, TAX * 3, fiat);
    }

    user.nextDeadline = block.timestamp + 28 days;
    user.bonusDeadline = block.timestamp + 7 days;
    user.walletAddress = msg.sender;
    totalRevenue += amount;
    user.balance += enterpriseJoin
        ? baseAmount - ENTERPRISE_JOIN_FEE
        : baseAmount - JOIN_FEE;

    if (referrers[_refCode] != address(0)) {
        user.collectiveCode = _refCode;
        users[referrers[user.collectiveCode]].balance += enterpriseJoin &&
            users[referrers[user.collectiveCode]].enterprise
            ? ((((90 * 10 ** 18) * 25) / 100))
            : (((25 * 10 ** 18) * 25) / 100);
        users[referrers[user.collectiveCode]].inviteCount++;
        emit RewardEarned(
            referrers[user.collectiveCode],
            block.timestamp,
            enterpriseJoin && users[referrers[user.collectiveCode]].enterprise
                ? ((((90 * 10 ** 18) * 25) / 100))
                : (((25 * 10 ** 18) * 25) / 100)
        );
        if (users[referrers[user.collectiveCode]].inviteCount % 3 == 0) {
            users[referrers[user.collectiveCode]].balance += enterpriseJoin &&
                users[referrers[user.collectiveCode]].enterprise
                ? ((((90 * 10 ** 18) * 25) / 100))
                : (((25 * 10 ** 18) * 25) / 100);
            emit RewardEarned(
                referrers[user.collectiveCode],
                block.timestamp,
                enterpriseJoin &&
                    users[referrers[user.collectiveCode]].enterprise
                    ? ((((90 * 10 ** 18) * 25) / 100))
                    : (((25 * 10 ** 18) * 25) / 100)
            );
        }
    }

    rewardQueue.push(msg.sender);

    if (refByAddr[msg.sender] == 0) {
        generateRefCode(msg.sender);
    }

    emit Joined(msg.sender, block.timestamp, amount, fiat);

    cascade(msg.sender);

    distributeFees(msg.sender, amount);
}
function withdrawFiat(
    uint256 amount,
    bool isFiat,
    uint8 fiatToWithdraw
) external nonReentrant {
    require(!isBlacklisted[msg.sender], "Blacklisted user");
    User storage user = users[msg.sender];
    uint limit = user.enterprise ? 127 * 10 ** 18 : 28 * 10 ** 18;
    uint balance;
    uint256 baseAmount = (amount * 1000) / 1015;
    if (!isFiat) {
        balance = user.balance;
    } else {
        balance = fiatToWithdraw == 1 ? user.balanceUSDT : user.balanceUSDC;
    }

    require(amount <= balance - limit, "Insufficient balance");

    if (!isFiat) {
        user.balance -= amount;
    } else {
        fiatToWithdraw == 1
            ? user.balanceUSDT -= amount
            : user.balanceUSDC -= amount;
    }

    fiatToWithdraw == 1
        ? usdt.transfer(msg.sender, baseAmount)
        : usdc.transfer(msg.sender, baseAmount);

    if (!isFiat) {
        distributeFees(msg.sender, amount);
    } else {
        distributeFeesFiat(msg.sender, amount, fiatToWithdraw);
    }

    emit WithdrawFiat(msg.sender, block.timestamp, amount, fiatToWithdraw);
}
