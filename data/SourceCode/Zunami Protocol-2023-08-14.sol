function balanceOf(address account) public view virtual override returns (uint256) {
  if (!containRigidAddress(account)) return super.balanceOf(account);

  return _balancesRigid[account];
}