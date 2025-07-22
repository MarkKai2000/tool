function withdraw(uint256 assets, address receiver) public virtual nonReentrant unPaused returns (uint256 shares) {
  require(assets != 0, "ZERO_ASSETS");
  require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

  // Total Assets amount until now
  uint256 totalDeposit = convertToAssets(balanceOf(msg.sender));

  require(assets <= totalDeposit, "EXCEED_TOTAL_DEPOSIT");

  // Calculate share amount to be burnt
  shares = (totalSupply() * assets) / totalAssets();

  // Calls Withdraw function on controller
  (uint256 withdrawn, uint256 fee) = IController(controller).withdraw(assets, receiver);

  require(withdrawn > 0, "INVALID_WITHDRAWN_SHARES");

  // Shares could exceed balance of caller
  if (balanceOf(msg.sender) < shares) shares = balanceOf(msg.sender);

  _burn(msg.sender, shares);

  emit Withdraw(address(asset), msg.sender, receiver, assets, shares, fee);
}