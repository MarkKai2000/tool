function depositAndBorrowApeAndStake(
  DepositInfo memory depositInfo,
  StakingInfo memory stakingInfo,
  IApeCoinStaking.SingleNft[] calldata _nfts,
  IApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
) external nonReentrant {
  address userAddr = msg.sender;
  address ptokenStaking = _getPTokenStaking(stakingInfo.nftAsset);

  // 1, handle borrow part and send ape to ptokenAddress
  if (stakingInfo.borrowAmount > 0) {
    uint256 borrowRate = IApePool(apePool).borrowRatePerBlock();
    uint256 stakingRate = getRewardRatePerBlock(_nftInfo[stakingInfo.nftAsset].poolId, stakingInfo.borrowAmount);
    require(borrowRate + stakingConfiguration.addMinStakingRate < stakingRate, "rate");
    IApePool(apePool).borrowBehalf(userAddr, stakingInfo.borrowAmount);
    IERC20Upgradeable(apeCoin).safeTransfer(ptokenStaking, stakingInfo.borrowAmount);
  }

  // 2, send cash part to ptokenAddress
  if (stakingInfo.cashAmount > 0) {
    IERC20Upgradeable(apeCoin).safeTransferFrom(userAddr, ptokenStaking, stakingInfo.cashAmount);
  }

  _depositNftToLending(userAddr, stakingInfo.nftAsset, depositInfo.mainTokenIds);
  _depositNftToLending(userAddr, BAKC_ADDR, depositInfo.bakcTokenIds);

  (uint256 nftAmount, uint256 nftPairAmount) = _storeUserInfo(userAddr, stakingInfo.nftAsset, _nfts, _nftPairs);

  // 3, deposit bayc or mayc pool
  if (_nfts.length > 0) {
    IPTokenApeStaking(ptokenStaking).depositApeCoin(nftAmount, _nfts);
  }

  // 4, deposit bakc pool
  if (_nftPairs.length > 0) {
    IPTokenApeStaking(ptokenStaking).depositBAKC(nftPairAmount, _nftPairs);
  }
}