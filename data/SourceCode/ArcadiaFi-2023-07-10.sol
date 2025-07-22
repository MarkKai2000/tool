function liquidateVault(uint256 openDebt)
  external
  returns (address originalOwner, address baseCurrency_, address trustedCreditor_)
{
  require(msg.sender == liquidator, "V_LV: Only Liquidator");

  //Cache trustedCreditor.
  
  trustedCreditor_ = trustedCreditor;

  //Close margin account.
  isTrustedCreditorSet = false;
  trustedCreditor = address(0);
  liquidator = address(0);

  //If getLiquidationValue (total value discounted with liquidation factor to account for slippage)
  //is smaller than the Used Margin: sum of the liabilities of the Vault (openDebt)
  //and the max gas cost to liquidate the vault (fixedLiquidationCost),
  //then the Vault can be successfully liquidated.
  //Liquidations are triggered by the trustedCreditor (via Liquidator), the openDebt is
  //passed as input to avoid the need of another contract call back to trustedCreditor.
  require(getLiquidationValue() < openDebt + fixedLiquidationCost, "V_LV: liqValue above usedMargin");

  //Set fixedLiquidationCost to 0 since margin account is closed.
  fixedLiquidationCost = 0;

  //Transfer ownership of the ERC721 in Factory of the Vault to the Liquidator.
  IFactory(IMainRegistry(registry).factory()).liquidate(msg.sender);

  //Transfer ownership of the Vault itself to the Liquidator.
  originalOwner = owner;
  _transferOwnership(msg.sender);

  emit TrustedMarginAccountChanged(address(0), address(0));

  return (originalOwner, baseCurrency, trustedCreditor_);
}