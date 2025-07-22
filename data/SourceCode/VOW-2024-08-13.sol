function transferFrom(
    TokenState storage _tokenState,
    address _from,
    address _to,
    uint256 _value
) external {
    _tokenState.approvals[_from][msg.sender] = _tokenState
    .approvals[_from][msg.sender].sub(_value, "Amount not approved");
    doSend(_tokenState, msg.sender, _from, _to, _value, "", "", false);
}

function transfer(
    address _to,
    uint256 _value
) external override returns (bool success_) {
    doSend(msg.sender, msg.sender, _to, _value, "", "", false);
    success_ = true;
}

function transferFrom(
    address _from,
    address _to,
    uint256 _value
) external override returns (bool success_) {
    LToken.transferFrom(tokenState, _from, _to, _value);
    success_ = true;
}

function getVOWVSCRate()
    public
    view
    returns (uint256 numVOW_, uint256 numVSC_)
{
    VSCToken vscToken = VSCToken(token);
    VOWToken vowToken = VOWToken(vowContract);
    numVOW_ = vowToken.usdRate(0).mul(vscToken.usdRate(1));
    numVSC_ = vowToken.usdRate(1).mul(vscToken.usdRate(0));
}

function tokensReceivedVOW(
    address _from,
    bytes memory _data,
    uint256 _amount
) private {
    if (registeredMVD[_from]) {
        (address merchant, bytes memory data) = abi.decode(
            _data,
            (address, bytes)
        );
        doMerchantLock(_from, merchant, _amount, data);
        return;
    }

    VOWToken(vowContract).burn(_amount, "");
    (uint256 numVOW, uint256 numVSC) = getVOWVSCRate();
    uint256 vscAmount = _amount.mul(numVSC).div(numVOW);
    VSCToken(token).mint(_from, vscAmount);

    emit LogBurnAndMint(_from, _amount, vscAmount);
}
