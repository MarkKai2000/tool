function swapTokenToToken(
    address _src,
    address _dest,
    uint _amount,
    uint _minPrice,
    uint _exchangeType,
    address _exchangeAddress,
    bytes memory _callData,
    uint _0xPrice
) public payable {
    // use this to avoid stack too deep error
    address[3] memory orderAddresses = [_exchangeAddress, _src, _dest];
    if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
        require(msg.value >= _amount, "msg.value smaller than amount");
    } else {
        require(
            ERC20(orderAddresses[1]).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Not able to withdraw wanted amount"
        );
    }
    uint fee = takeFee(_amount, orderAddresses[1]);
    _amount = sub(_amount, fee);
    // [tokensReturned, tokensLeft]
    uint[2] memory tokens;
    address wrapper;
    uint price;
    bool success;
    // at the beggining tokensLeft equals _amount
    tokens[1] = _amount;
    if (_exchangeType == 4) {
        if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
            ERC20(orderAddresses[1]).approve(address(ERC20_PROXY_0X), _amount);
        }
        (success, tokens[0], ) = takeOrder(
            orderAddresses,
            _callData,
            address(this).balance,
            _amount
        );
        // either it reverts or order doesn't exist anymore, we reverts as it was explicitely asked for this exchange
        require(success && tokens[0] > 0, "0x transaction failed");
        wrapper = address(_exchangeAddress);
    }
    if (tokens[0] == 0) {
        (wrapper, price) = getBestPrice(
            _amount,
            orderAddresses[1],
            orderAddresses[2],
            _exchangeType
        );
        require(price > _minPrice || _0xPrice > _minPrice, "Slippage hit");
        // handle 0x exchange, if equal price, try 0x to use less gas
        if (_0xPrice >= price) {
            if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
                ERC20(orderAddresses[1]).approve(
                    address(ERC20_PROXY_0X),
                    _amount
                );
            }
            (success, tokens[0], tokens[1]) = takeOrder(
                orderAddresses,
                _callData,
                address(this).balance,
                _amount
            );
            // either it reverts or order doesn't exist anymore
            if (success && tokens[0] > 0) {
                wrapper = address(_exchangeAddress);
                emit Swap(
                    orderAddresses[1],
                    orderAddresses[2],
                    _amount,
                    tokens[0],
                    wrapper
                );
            }
        }
        if (tokens[1] > 0) {
            // in case 0x swapped just some amount of tokens and returned everything else
            if (tokens[1] != _amount) {
                (wrapper, price) = getBestPrice(
                    tokens[1],
                    orderAddresses[1],
                    orderAddresses[2],
                    _exchangeType
                );
            }
            // in case 0x failed, price on other exchanges still needs to be higher than minPrice
            require(price > _minPrice, "Slippage hit onchain price");
            if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
                (tokens[0], ) = ExchangeInterface(wrapper)
                    .swapEtherToToken
                    .value(tokens[1])(tokens[1], orderAddresses[2], uint(-1));
            } else {
                ERC20(orderAddresses[1]).transfer(wrapper, tokens[1]);
                if (orderAddresses[2] == KYBER_ETH_ADDRESS) {
                    tokens[0] = ExchangeInterface(wrapper).swapTokenToEther(
                        orderAddresses[1],
                        tokens[1],
                        uint(-1)
                    );
                } else {
                    tokens[0] = ExchangeInterface(wrapper).swapTokenToToken(
                        orderAddresses[1],
                        orderAddresses[2],
                        tokens[1]
                    );
                }
            }
            emit Swap(
                orderAddresses[1],
                orderAddresses[2],
                _amount,
                tokens[0],
                wrapper
            );
        }
    }
    // return whatever is left in contract
    if (address(this).balance > 0) {
        msg.sender.transfer(address(this).balance);
    }
    // return if there is any tokens left
    if (orderAddresses[2] != KYBER_ETH_ADDRESS) {
        if (ERC20(orderAddresses[2]).balanceOf(address(this)) > 0) {
            ERC20(orderAddresses[2]).transfer(
                msg.sender,
                ERC20(orderAddresses[2]).balanceOf(address(this))
            );
        }
    }
    if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
        if (ERC20(orderAddresses[1]).balanceOf(address(this)) > 0) {
            ERC20(orderAddresses[1]).transfer(
                msg.sender,
                ERC20(orderAddresses[1]).balanceOf(address(this))
            );
        }
    }
}
