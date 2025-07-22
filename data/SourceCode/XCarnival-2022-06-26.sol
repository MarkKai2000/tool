// in the 0x39360AC1239a0b98Cb8076d4135d0F72B7fd9909
function pledgeAndBorrow(
    address _collection,
    uint256 _tokenId,
    uint256 _nftType,
    address xToken,
    uint256 borrowAmount
) external nonReentrant {
    uint256 orderId = pledgeInternal(_collection, _tokenId, _nftType);
    IXToken(xToken).borrow(orderId, payable(msg.sender), borrowAmount);
}

function pledgeInternal(
    address _collection,
    uint256 _tokenId,
    uint256 _nftType
) internal whenNotPaused(1) returns (uint256) {
    require(_nftType == 721 || _nftType == 1155, "don't support this nft type");
    if (_collection != address(punks)) {
        transferNftInternal(
            msg.sender,
            address(this),
            _collection,
            _tokenId,
            _nftType
        );
    } else {
        _depositPunk(_tokenId);
        _collection = address(wrappedPunks);
    }
    require(
        collectionWhiteList[_collection].isCollectionWhiteList,
        "collection not insist"
    );

    counter = counter.add(1);
    uint256 _orderId = counter;
    Order storage _order = allOrders[_orderId];
    _order.collection = _collection;
    _order.tokenId = _tokenId;
    _order.nftType = _nftType;
    _order.pledger = msg.sender;

    ordersMap[msg.sender].push(counter);

    emit Pledge(_collection, _tokenId, _orderId, msg.sender);
    return _orderId;
}

function withdrawNFT(uint256 orderId) external nonReentrant whenNotPaused(2) {
    LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
    Order storage _order = allOrders[orderId];
    if (isOrderLiquidated(orderId)) {
        require(
            liquidatedOrder.auctionWinner == address(0),
            "the order has been withdrawn"
        );
        require(
            !allLiquidatedOrder[orderId].isPledgeRedeem,
            "redeemed by the pledgor"
        );
        CollectionNFT memory collectionNFT = collectionWhiteList[
            _order.collection
        ];
        uint256 auctionDuration;
        if (collectionNFT.auctionDuration != 0) {
            auctionDuration = collectionNFT.auctionDuration;
        } else {
            auctionDuration = auctionDurationOverAll;
        }
        require(
            block.timestamp >
                liquidatedOrder.liquidatedStartTime.add(auctionDuration),
            "the auction is not yet closed"
        );
        require(
            msg.sender == liquidatedOrder.auctionAccount ||
                (liquidatedOrder.auctionAccount == address(0) &&
                    msg.sender == liquidatedOrder.liquidator),
            "you can't extract NFT"
        );
        transferNftInternal(
            address(this),
            msg.sender,
            _order.collection,
            _order.tokenId,
            _order.nftType
        );
        if (
            msg.sender == liquidatedOrder.auctionAccount &&
            liquidatedOrder.auctionPrice != 0
        ) {
            uint256 profit = liquidatedOrder.auctionPrice.sub(
                liquidatedOrder.liquidatedPrice
            );
            uint256 compensatePledgerAmount = profit
                .mul(compensatePledgerRate)
                .div(1e18);
            doTransferOut(
                liquidatedOrder.xToken,
                payable(_order.pledger),
                compensatePledgerAmount
            );
            uint256 liquidatorAmount = profit.mul(rewardFirstRate).div(1e18);
            doTransferOut(
                liquidatedOrder.xToken,
                payable(liquidatedOrder.liquidator),
                liquidatorAmount
            );

            addUpIncomeMap[liquidatedOrder.xToken] =
                addUpIncomeMap[liquidatedOrder.xToken] +
                (profit - compensatePledgerAmount - liquidatorAmount);
        }
        liquidatedOrder.auctionWinner = msg.sender;
    } else {
        require(!_order.isWithdraw, "the order has been drawn");
        require(
            _order.pledger != address(0) && msg.sender == _order.pledger,
            "withdraw auth failed"
        );
        uint256 borrowBalance = controller.getOrderBorrowBalanceCurrent(
            orderId
        );
        require(borrowBalance == 0, "order has debt");
        transferNftInternal(
            address(this),
            _order.pledger,
            _order.collection,
            _order.tokenId,
            _order.nftType
        );
    }
    _order.isWithdraw = true;
    emit WithDraw(
        _order.collection,
        _order.tokenId,
        orderId,
        _order.pledger,
        msg.sender
    );
}

// in the 0x5417da20aC8157Dd5c07230Cfc2b226fDCFc5663
function borrow(
    uint256 orderId,
    address payable borrower,
    uint256 borrowAmount
) external {
    require(
        msg.sender == borrower || tx.origin == borrower,
        "borrower is wrong"
    );
    accrueInterest();
    borrowInternal(orderId, borrower, borrowAmount);
}
