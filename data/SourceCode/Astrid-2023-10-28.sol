    function withdraw(address _restakedTokenAddress, uint256 amount) public nonReentrant whenNotPaused {
        require(Utils.contractExists(_restakedTokenAddress), "AstridProtocol: Contract does not exist");
        require(amount > 0, "AstridProtocol: Amount must be greater than 0");
        require(IERC20(_restakedTokenAddress).balanceOf(msg.sender) >= amount, "AstridProtocol: Insufficient balance of restaked token");
        require(IERC20(_restakedTokenAddress).allowance(msg.sender, address(this)) >= amount, "AstridProtocol: Insufficient allowance of restaked token");

        uint256 sharesBefore = IRestakedETH(_restakedTokenAddress).scaledBalanceOf(address(this));

        // receive restaked token from user to "lock" it
        bool amountSent = Utils.payMe(msg.sender, amount, _restakedTokenAddress);
        require(amountSent, "AstridProtocol: Failed to send restaked token");

        uint256 sharesAfter = IRestakedETH(_restakedTokenAddress).scaledBalanceOf(address(this));
        uint256 shares = sharesAfter.sub(sharesBefore); // we store shares of restakedETH to ensure that it is still subject to rebase when locked

        WithdrawalRequest memory request = WithdrawalRequest({
            withdrawer: msg.sender,
            restakedTokenAddress: _restakedTokenAddress,
            amount: amount,
            requestedRestakedTokenShares: shares,
            claimableStakedTokenAmount: 0, // placeholder
            status: WithdrawalStatus.REQUESTED,
            withdrawalStartBlock: uint32(block.number),
            withdrawRequestedAt: block.timestamp,
            withdrawProcessedAt: 0,
            withdrawClaimedAt: 0,
            withdrawalRequestsIndex: withdrawalRequests.length,
            withdrawalRequestsByUserIndex: withdrawalRequestsByUser[msg.sender].length
        });

        totalWithdrawalRequests[_restakedTokenAddress] += shares;
        withdrawalRequests.push(request);
        withdrawalRequestsByUser[msg.sender].push(request);

        emit WithdrawalRequested(msg.sender, _restakedTokenAddress, amount, shares);

        if (processWithdrawalsOnWithdraw) {
            _processWithdrawals();
        }
    }