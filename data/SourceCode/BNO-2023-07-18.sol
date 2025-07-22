function updatePool() public {
    uint256 curBlock = poolInfo.endBlock < block.number ? poolInfo.endBlock : block.number;
    
    if (poolInfo.stakeSupply == 0) {
        poolInfo.lastRewardBlock = curBlock;
        return;
    }
    if(userInfo[msg.sender].nftAddition != 0){
        poolInfo.nftAddition = poolInfo.nftAddition.sub(userInfo[msg.sender].nftAddition);
    }
    userInfo[msg.sender].nftAddition = userInfo[msg.sender].allstake.mul(userInfo[msg.sender].nftAmount).mul(poolInfo.nftWeights).div(100);
    poolInfo.nftAddition = poolInfo.nftAddition.add(userInfo[msg.sender].nftAddition);

    uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, curBlock);
    uint256 fitReward = multiplier.mul(perBlock);
    poolInfo.accPerShare = poolInfo.accPerShare.add(
        fitReward.mul(1e12).div(poolInfo.stakeSupply.add(poolInfo.nftAddition))
    );
    poolInfo.lastRewardBlock = curBlock;
    
    }

function emergencyWithdraw() public {
    pledgeAddress.safeTransfer(address(msg.sender), userInfo[msg.sender].allstake);
    userInfo[msg.sender].allstake = 0;
    userInfo[msg.sender].rewardDebt = 0;
}

function pendingFit(address _user) public view returns(uint256){
    uint256 curBlock = poolInfo.endBlock < block.number ? poolInfo.endBlock : block.number;
    UserInfo storage user = userInfo[_user];
    uint256 accPerShare = poolInfo.accPerShare;

    if (curBlock > poolInfo.lastRewardBlock && poolInfo.stakeSupply != 0) {
        uint256 multiplier =
            getMultiplier(poolInfo.lastRewardBlock, curBlock);
        uint256 fitReward =
            multiplier.mul(perBlock);
        accPerShare = accPerShare.add(
            fitReward.mul(1e12).div(poolInfo.stakeSupply.add(poolInfo.nftAddition))
        );
    }

    uint256 userreward = (user.allstake.add(user.nftAddition)).mul(accPerShare).div(1e12).sub(user.rewardDebt);
    return userreward;
}