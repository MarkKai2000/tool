function getUserCanMint(address account) public view returns (uint256) {
    uint256 userStartTime = userBalanceTime[account];
    uint256 haveAmount = super.balanceOf(account);
    if (
        userStartTime > 0 &&
        haveAmount >= 10 ** 20 &&
        tokenStartTime < block.timestamp &&
        maxCanMint &&
        managerCanMint
    ) {
        uint256 secondAmount = haveAmount.div(100).div(86400);
        uint256 afterSecond = block.timestamp.sub(userStartTime);
        return secondAmount.mul(afterSecond);
    }
    return 0;
}

function updateUserBalance(address _user) public {
    uint256 totalAmountOver = super.totalSupply();
    if (maxTotal <= totalAmountOver) {
        maxCanMint = false;
    }

    if (userBalanceTime[_user] > 0) {
        uint256 canMint = getUserCanMint(_user);
        if (canMint > 0) {
            userBalanceTime[_user] = block.timestamp;
            _mint(_user, canMint);
        }
    } else {
        userBalanceTime[_user] = block.timestamp;
    }
}
