function buy(uint256 lifeTokenAmount) external nonReentrant {
    uint256 totalUsdtCost = calculateTotalCost(lifeTokenAmount);
    require(
        totalUsdtCost >= minTradeAmount && totalUsdtCost <= maxTradeAmount,
        "Invalid trade amount"
    );

    buyBackReserve = buyBackReserve.add(totalUsdtCost);

    require(
        UsdtToken.transferFrom(msg.sender, address(this), totalUsdtCost),
        "usdt transfer failed!"
    );

    uint256 contractTokenBalance = lifeToken.balanceOf(address(this));
    uint256 availableSupply = contractTokenBalance > queueSupply
        ? contractTokenBalance.sub(queueSupply)
        : 0;
    uint256 deficit = 0;

    if (availableSupply >= lifeTokenAmount) {
        buyFromSupply(msg.sender, lifeTokenAmount);
    } else {
        deficit = lifeTokenAmount.sub(availableSupply);
        if (availableSupply > 0) {
            buyFromSupply(msg.sender, availableSupply);
        }
        buyFromSellOrders(msg.sender, deficit);
    }
    buyBack();
    handleRatio(totalUsdtCost);
}

function referredBuy(
    address _user,
    uint256 _usdtAmount,
    uint256 _usdtDiscount
) public onlyLifeProtocolAffiliate {
    require(_usdtAmount > 0, "Incorrect usdt amount sent");
    uint256 totalUsdtAmount = _usdtAmount.add(_usdtDiscount);
    uint256 totalLifeTokenAmount = calculateTokenAmount(totalUsdtAmount);
    require(
        totalUsdtAmount >= minTradeAmount && totalUsdtAmount <= maxTradeAmount,
        "Invalid USDT trade amount"
    );
    buyBackReserve = buyBackReserve.add(_usdtAmount);

    uint256 contractTokenBalance = lifeToken.balanceOf(address(this));
    uint256 availableSupply = contractTokenBalance > queueSupply
        ? contractTokenBalance.sub(queueSupply)
        : 0;
    uint256 deficit = 0;

    if (availableSupply >= totalLifeTokenAmount) {
        buyFromSupply(_user, totalLifeTokenAmount);
    } else {
        deficit = totalLifeTokenAmount.sub(availableSupply);

        if (availableSupply > 0) {
            buyFromSupply(_user, availableSupply);
        }
        buyFromSellOrders(_user, deficit);
    }
    buyBack();
    handleRatio(totalUsdtAmount);
}

function sell(uint256 amount) external nonReentrant {
    require(lifeToken.balanceOf(msg.sender) >= amount, "Insufficient balance");

    bytes32 sellOrderId = generateSellOrderId();
    bytes32 previousOrderId = currentSellOrderId;

    uint256 sellPrice = currentPrice.mul(90).div(100);
    uint256 requiredUSDT = sellPrice.mul(amount).div(1e18);
    require(
        requiredUSDT >= minTradeAmount && requiredUSDT <= maxTradeAmount,
        "Invalid  Usdt trade amount"
    );

    sellOrders[sellOrderId] = SellOrder({
        sellOrderId: sellOrderId,
        amount: amount,
        price: sellPrice,
        previous: previousOrderId,
        next: bytes32(0),
        seller: msg.sender,
        canceled: false,
        bought: false
    });

    if (UsdtToken.balanceOf(address(this)) >= requiredUSDT) {
        lifeToken.transferFrom(msg.sender, address(this), amount);
        remainingSupply = remainingSupply.add(amount);
        buyBackReserve = buyBackReserve.sub(requiredUSDT);
        require(
            UsdtToken.transfer(msg.sender, requiredUSDT),
            "usdt transfer failed!"
        );
        sellOrders[sellOrderId].bought = true;
        if (sellOrders[previousOrderId].next == sellOrderId) {
            currentSellOrderId = sellOrders[sellOrderId].next;
        }

        emit SellOrderCompleted(sellOrderId, msg.sender);
    } else {
        lifeToken.transferFrom(msg.sender, address(this), amount);
        queueSupply = queueSupply.add(amount);

        if (currentSellOrderId != bytes32(0)) {
            sellOrders[currentSellOrderId].next = sellOrderId;
        }

        if (currentSellOrderId == bytes32(0)) {
            currentSellOrderId = sellOrderId;
        }

        sellOrderCounter = sellOrderCounter.add(1);

        sellerOrders[msg.sender].push(sellOrderId);

        emit SellOrderCreated(
            sellOrderId,
            uint256(amount),
            uint256(sellPrice),
            msg.sender
        );
    }
    buyBack();
}

function buyBack() internal {
    if (
        currentSellOrderId != bytes32(0) &&
        buyBackReserve >
        sellOrders[currentSellOrderId]
            .amount
            .mul(sellOrders[currentSellOrderId].price)
            .div(1e18)
    ) {
        resolveBuyback();
    }
}

function resolveBuyback() internal {
    SellOrder storage order = sellOrders[currentSellOrderId];
    uint256 amount = order.amount;
    uint256 price = order.price;

    require(
        buyBackReserve >= amount.mul(price).div(1e18),
        "Insufficient buyBack reserve"
    );
    buyBackReserve = buyBackReserve.sub(amount.mul(price).div(1e18));
    lifeToken.transferFrom(order.seller, address(this), amount);
    queueSupply = queueSupply.sub(amount);
    UsdtToken.transfer(order.seller, amount.mul(price).div(1e18));
    order.bought = true;
    currentSellOrderId = order.next;

    emit BuyBackExecuted(amount, price);
    emit SellOrderCompleted(order.sellOrderId, order.seller);
}
