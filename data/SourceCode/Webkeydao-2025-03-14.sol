function setSaleInfo(
    uint256 _available,
    uint256 _price,
    uint256 _totalTokens,
    uint256 _immediateReleaseTokens
) external {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
    require(_available > 0, "Available stock must be greater than zero");
    require(
        _totalTokens >= _immediateReleaseTokens,
        "Total tokens must be greater or equal to immediate release tokens"
    );
    if (currentSaleInfo.price != 0) {
        saleHistory.push(currentSaleInfo);
    }
    currentSaleInfo = SaleInfo({
        price: _price,
        totalTokens: _totalTokens,
        immediateReleaseTokens: _immediateReleaseTokens,
        available: _available,
        initialAvailable: _available,
        timestamp: block.timestamp,
        operator: msg.sender
    });
}
function buy() external {
    require(currentSaleInfo.available > 0, "Out of stock");
    require(
        usdt.transferFrom(msg.sender, address(this), currentSaleInfo.price),
        "USDT payment failed"
    );

    currentSaleInfo.available -= 1;
    uint256 immediateTokens = currentSaleInfo.immediateReleaseTokens;
    uint256 totalTokens = currentSaleInfo.totalTokens;

    console.log("to get nextTokenId");
    uint256 tokenId = nft.nextTokenId();

    console.log("to mint");
    nft.mint(msg.sender);

    buyers[msg.sender].push(
        BuyerInfo({
            price: currentSaleInfo.price,
            totalTokens: totalTokens,
            immediateReleased: immediateTokens,
            releasedTokens: immediateTokens,
            releaseCount: 1,
            tokenId: tokenId
        })
    );

    console.log("to transfer immediateTokens");
    if (immediateTokens > 0) {
        console.log("to mint wkey");
        IMintable(wkey).mint(address(this), immediateTokens);
        console.log("to transfer wkey");
        require(
            IERC20Upgradeable(wkey).transfer(msg.sender, immediateTokens),
            "WKEY transfer failed"
        );
    }

    // Distribute commissions
    address firstReferer = community.referrerOf(msg.sender);
    console.log("firstReferer", firstReferer);

    if (firstReferer != address(0)) {
        uint256 firstCommission = (currentSaleInfo.price *
            firstLevelCommission) / 100;
        require(
            usdt.transfer(firstReferer, firstCommission),
            "First level commission transfer failed"
        );

        address secondReferer = community.referrerOf(firstReferer);
        if (secondReferer != address(0)) {
            uint256 secondCommission = (currentSaleInfo.price *
                secondLevelCommission) / 100;
            require(
                usdt.transfer(secondReferer, secondCommission),
                "Second level commission transfer failed"
            );
        }
    }

    // Distribute DAO reward
    console.log("to distribute dao reward");
    uint256 daoRewardAmount = (currentSaleInfo.price * daoRewardCommission) /
        100;
    daoReward.addReward(msg.sender, daoRewardAmount);
}
