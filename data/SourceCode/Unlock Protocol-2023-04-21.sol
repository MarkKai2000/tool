function postLockUpgrade() public {
// check if lock hasnot already been deployed here and version is correct
if (
    locks[msg.sender].deployed == false
    && 
    IPublicLock(msg.sender).publicLockVersion() == 13 
    && 
    IPublicLock(msg.sender).unlockProtocol() != address(this)
) {
    IUnlock previousUnlock = IUnlock(
    IPublicLock(msg.sender).unlockProtocol()
    );

    (
    bool deployed, 
    uint totalSales, 
    uint yieldedDiscountTokens
    ) = previousUnlock.locks(msg.sender);

    // record lock from old Unlock in this one
    if (deployed) {
        locks[msg.sender] = LockBalances(
        deployed, 
        totalSales, 
        yieldedDiscountTokens
        );
    } else {
    revert Unlock__MISSING_LOCK(msg.sender);
    }
}
}

  
  function recordKeyPurchase(
    uint _value,
    address _referrer
  ) public onlyFromDeployedLock {
    if (_value > 0) {
      uint valueInETH;
      address tokenAddress = IPublicLock(msg.sender)
        .tokenAddress();
      if (
        tokenAddress != address(0) && tokenAddress != weth
      ) {
        // If priced in an ERC-20 token, find the supported uniswap oracle
        IUniswapOracleV3 oracle = uniswapOracles[
          tokenAddress
        ];
        if (address(oracle) != address(0)) {
          valueInETH = oracle.updateAndConsult(
            tokenAddress,
            _value,
            weth
          );
        }
      } else {
        // If priced in ETH (or value is 0), no conversion is required
        valueInETH = _value;
      }

      updateGrossNetworkProduct(
        valueInETH,
        tokenAddress,
        _value,
        msg.sender // lockAddress
      );

      // If GNP does not overflow, the lock totalSales should be safe
      locks[msg.sender].totalSales += valueInETH;

      // Distribute UDT
      // version 13 is the first version for which locks can be paying the fee. Prior versions should not distribute UDT if they don't "pay" the fee.
      if (_referrer != address(0) && IPublicLock(msg.sender).publicLockVersion() <= 13) {
        IUniswapOracleV3 udtOracle = uniswapOracles[udt];
        if (address(udtOracle) != address(0)) {
          // Get the value of 1 UDT (w/ 18 decimals) in ETH
          uint udtPrice = udtOracle.updateAndConsult(
            udt,
            10 ** 18,
            weth
          );

          uint balance = IMintableERC20(udt).balanceOf(
            address(this)
          );

          // base fee default to 100 GWEI for chains that does
          uint baseFee;
          try this.networkBaseFee() returns (
            uint _basefee
          ) {
            // no assigned value
            if (_basefee == 0) {
              baseFee = 100;
            } else {
              baseFee = _basefee;
            }
          } catch {
            // block.basefee not supported
            baseFee = 100;
          }

          // tokensToDistribute is either == to the gas cost times 1.25 to cover the 20% dev cut
          uint tokensToDistribute = ((estimatedGasForPurchase *
              baseFee) * (125 * 10 ** 18)) /
              100 /
              udtPrice;

          // or tokensToDistribute is capped by network GDP growth
          // we distribute tokens using asymptotic curve between 0 and 0.5
          uint maxTokens = (balance * valueInETH) /
            (2 + (2 * valueInETH) / grossNetworkProduct) /
            grossNetworkProduct;

          // cap to GDP growth!
          if (tokensToDistribute > maxTokens) {
            tokensToDistribute = maxTokens;
          }

          if (tokensToDistribute > 0) {
            // 80% goes to the referrer, 20% to the Unlock dev - round in favor of the referrer
            uint devReward = (tokensToDistribute * 20) / 100;
            
            if (balance > tokensToDistribute) {
              // Only distribute if there are enough tokens
              IMintableERC20(udt).transfer(
                _referrer,
                tokensToDistribute - devReward
              );
              IMintableERC20(udt).transfer(
                owner(),
                devReward
              );
            }
          }
        }
      }
    }
  }

modifier onlyFromDeployedLock() {
require(locks[msg.sender].deployed, "ONLY_LOCKS");
_;
}