function bindParent(address parent) public {
    address inviter = inv.getInviter(msg.sender);
    if (inviter == address(0) && parent != address(0)) {
        inv.invite(msg.sender, parent);
    }
}

function getReward() public updateReward(msg.sender) checkStart {
    uint256 reward = dynamicEarned(msg.sender) + privateEarned(msg.sender);
    if (reward > 0) {
        prewards[msg.sender] = 0;
        drewards[msg.sender] = 0;

        token.safeTransfer(msg.sender, reward);

        emit RewardPaid(msg.sender, reward);
        totalRewards = totalRewards.add(reward);
    }
}

modifier updateReward(address account) {
    if (block.timestamp > starttime) {
        rewardPerTokenStored = rewardPerToken();

        nodeRewardPerTokenStored1 = nodeRewardPerToken(1);
        nodeRewardPerTokenStored2 = nodeRewardPerToken(2);
        nodeRewardPerTokenStored3 = nodeRewardPerToken(3);
        nodeRewardPerTokenStored4 = nodeRewardPerToken(4);

        flag = true;

        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            prewards[account] = privateEarned(account);
            drewards[account] = dynamicEarned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;

            nodeRewards[account] = nodeEarned(account);
            nodeUserRewardPerTokenPaid1[account] = nodeRewardPerTokenStored1;
            nodeUserRewardPerTokenPaid2[account] = nodeRewardPerTokenStored2;
            nodeUserRewardPerTokenPaid3[account] = nodeRewardPerTokenStored3;
            nodeUserRewardPerTokenPaid4[account] = nodeRewardPerTokenStored4;
        }
    }
    _;
}


function dynamicEarned(address account) public view returns (uint256) {
    if (block.timestamp < starttime) {
        return 0;
    }

    if (balanceOf(account) < 10e18) {
        return 0;
    }
    
    return
        _getMyChildersBalanceOf(account)
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .mul(45)
            .div(precision)
            .div(100);
}

function _getMyChildersBalanceOf(address user)
    private
    view
    returns (uint256)
{
    address[] memory childers = inv.getInviterSuns(user);

    uint256 totalBalances;
    for (uint256 index = 0; index < childers.length; index++) {
        totalBalances += balanceOf(childers[index]);
    }

    return totalBalances;
}