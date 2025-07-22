function selfSwap(SwapTypes.SelfSwap calldata request) external notPaused {
    //we create a swap request that has no affiliate attached and thus no
    //automatic discount.
    SwapTypes.SwapRequest memory swapReq = SwapTypes.SwapRequest({
        executionRequest: ExecutionTypes.ExecutionRequest({
            fee: ExecutionTypes.FeeDetails({
                feeToken: request.feeToken,
                affiliate: address(0),
                affiliatePortion: 0
            }),
            requester: msg.sender
        }),
        tokenIn: request.tokenIn,
        tokenOut: request.tokenOut,
        routes: request.routes
    });
    SwapMeta memory details = SwapMeta({
        feeIsInput: false,
        isSelfSwap: true,
        startGas: 0,
        preSwapVault: address(DexibleStorage.load().communityVault),
        bpsAmount: 0,
        gasAmount: 0,
        nativeGasAmount: 0,
        toProtocol: 0,
        toRevshare: 0,
        outToTrader: 0,
        preDXBLBalance: 0,
        outAmount: 0,
        inputAmountDue: 0
    });
    details = this.fill(swapReq, details);
    postFill(swapReq, details, true);
}

function withdraw(uint amount) public onlyAdmin {
    address payable rec = payable(msg.sender);
    require(rec.send(amount), "Transfer failed");
    emit WithdrewETH(msg.sender, amount);
}

function fill(SwapTypes.SwapRequest calldata request, SwapMeta memory meta) external onlySelf returns (SwapMeta memory)  {

    preCheck(request, meta);
    meta.outAmount = request.tokenOut.token.balanceOf(address(this));
    
    for(uint i=0;i<request.routes.length;++i) {
        SwapTypes.RouterRequest calldata rr = request.routes[i];
        IERC20(rr.routeAmount.token).safeApprove(rr.spender, rr.routeAmount.amount);
        (bool s, ) = rr.router.call(rr.routerData);

        if(!s) {
            revert("Failed to swap");
        }
    }
    uint out = request.tokenOut.token.balanceOf(address(this));
    if(meta.outAmount < out) {
        meta.outAmount = out - meta.outAmount;
    } else {
        meta.outAmount = 0;
    }
    
    console.log("Expected", request.tokenOut.amount, "Received", meta.outAmount);
    //first, make sure enough output was generated
    require(meta.outAmount >= request.tokenOut.amount, "Insufficient output generated");
    return meta;
}