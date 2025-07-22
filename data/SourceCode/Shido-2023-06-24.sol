function lockTokens() external {
  uint256 amount = IERC20(shidoV1).balanceOf(msg.sender);
  if (amount == 0) revert ZeroAmount();
  userShidoV1[msg.sender] += amount;
  IERC20(shidoV1).transferFrom(msg.sender, rewardWallet, amount);
}

function claimTokens() external {
  if (block.timestamp < lockTimestamp) revert WaitNotOver();
  uint256 amount = userShidoV1[msg.sender] * 10 ** 9;
  if (amount == 0) revert ZeroAmount();
  userShidoV1[msg.sender] = 0;
  userShidoV2[msg.sender] += amount;
  IERC20(shidoV2).transferFrom(rewardWallet, msg.sender, amount);
}