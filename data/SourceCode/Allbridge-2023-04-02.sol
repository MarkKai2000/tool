// Subtract X and Y for that amount, calculate current price and withdraw the token to the user according to the price
function withdraw(uint256 amountLp) external {
    uint256 totalLpAmount_ = totalLpAmount; // Gas optimization

    _withdrawLp(msg.sender, amountLp);

    // Calculate actual and virtual tokens using burned LP amount share
    // Swap the difference, get total amount to transfer/burn
    uint256 amountSP = _preWithdrawSwap(
        (tokenBalance * amountLp) / totalLpAmount_,
        (vUsdBalance * amountLp) / totalLpAmount_
    );

    // Always equal amounts removed from actual and virtual tokens
    tokenBalance -= amountSP;
    vUsdBalance -= amountSP;

    // Update D and transfer tokens to the sender
    _updateD();
    token.safeTransfer(msg.sender, fromSystemPrecision(amountSP));
}

// Withdraws LP amount for the user, updates user reward debt and pays pending rewards
function _withdrawLp(address from, uint256 lpAmount) internal {
    UserInfo storage user = userInfo[from];
    uint256 userLpAmount_ = user.lpAmount; // Gas optimization
    require(userLpAmount_ >= lpAmount, "RewardManager: not enough amount");
    uint256 pending;
    if (userLpAmount_ > 0) {
        pending = ((userLpAmount_ * accRewardPerShareP) >> P) - user.rewardDebt;
    }
    totalLpAmount -= lpAmount;
    userLpAmount_ -= lpAmount;
    user.lpAmount = userLpAmount_;
    user.rewardDebt = (userLpAmount_ * accRewardPerShareP) >> P;
    if (pending > 0) {
        token.safeTransfer(from, pending);
        emit RewardsClaimed(from, pending);
    }
    emit Withdraw(from, lpAmount);
}
