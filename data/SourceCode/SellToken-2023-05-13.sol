function stake(address token,address token1,address token2,address up,uint amount) external{
    require(users[token][up].tz > 0 || msg.sender == owner());
    if(token2 == SELLC){
        require(getTokenPriceUs(amount) >= 100 ether );
    }else {
        require(amount >= 100 ether ); 
    }
    require(token2 == USDT || token2==SELLC);
    require(listToken[token]);
    require(token1== USDT || token1==SELLC);
    address pair=ISwapFactory(IRouters.factory()).getPair(token,token1);
    require(pair!=address(this));
    require(amount > 0,"amount can not be 0");
    bool isok=IERC20(token2).transferFrom(msg.sender, address(this), amount);
    require(isok);
    uint SELL=amount;
    if(token1 == SELLC && token2 ==USDT){
        uint sellcx=_buySellc(amount);
        require(sellcx > 0);
        SELL=sellcx;
    }
    if(stakedOfTime[token][msg.sender] ==0){
        stakedOfTime[token][msg.sender]=block.timestamp;
    }else {
        claim(token,token1);
    }
    users[token][msg.sender].mnu++;
    IERC20(token1).transfer(auditor,SELL * 2 / 100);
    IERC20(token1).transfer(TokenOwner[token],SELL * 1 / 100);
    //TokenOwner[_token]
    uint buyToken=_buy(token1,token,SELL * 49 / 100);
    require(buyToken > 0);
    _addL(token,token1,buyToken,SELL*48/100,address(this));       
    stakedOfTimeSum[token][msg.sender][users[token][msg.sender].mnu]=RATE_DAY * 365;
    stakedOf[token][msg.sender][users[token][msg.sender].mnu] += SELL;
    stakedSum[token][address(this)]+=SELL;
    if(upaddress[msg.sender] == address(0) && up != msg.sender){
        upaddress[msg.sender]=up;
        usersAddr[up].arrs.push(msg.sender);
    }
    users[token][msg.sender].tz+=SELL;
}

function claim(address token,address token1) public    {
    require(listToken[token]);
    require(users[token][msg.sender].mnu > 0);
    require(block.timestamp > stakedOfTime[token][msg.sender]);
    uint minit=block.timestamp-stakedOfTime[token][msg.sender];
    uint coin;
    for(uint i=0;i< users[token][msg.sender].mnu;i++){
        if(stakedOfTimeSum[token][msg.sender][i+1] > minit && stakedOf[token][msg.sender][i+1] >0){
        uint banOf=stakedOf[token][msg.sender][i+1] / 100;
        uint send=getTokenPrice(token1,token,banOf) / RATE_DAY;
            coin+=minit*send;
            stakedOfTimeSum[token][msg.sender][i+1]-=minit;
        }
    }
    bool isok=IERC20(token).transfer(msg.sender,coin*50/100);
    require(isok);
    stakedOfTime[token][msg.sender]=block.timestamp;
    updateU(token,msg.sender,coin*50/100);
}


function getTokenPrice(address usdt,address _tolens,uint bnb) view private  returns(uint){
        address[] memory routePath = new address[](2);
        routePath[0] = usdt;
        routePath[1] = _tolens;
        return IRouters.getAmountsOut(bnb,routePath)[1];    
}