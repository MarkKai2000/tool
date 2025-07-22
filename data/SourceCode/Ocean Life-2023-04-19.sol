function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
}

function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    // Remove fees for transfers to and from charity account or to excluded account
    bool takeFee = true;
    if (_isCharity[sender] || _isCharity[recipient] || _isExcluded[recipient]) {
        takeFee = false;
    }

    if (!takeFee) removeAllFee();
    
    if (sender != owner() && recipient != owner())
        require(amount <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");
    
    if (_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
        _transferBothExcluded(sender, recipient, amount);
    } else {
        _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) restoreAllFee();
}


function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tCharity) = _getValues(tAmount);
    uint256 rBurn =  tBurn.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);     
    _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
    _sendToCharity(tCharity, sender);
    _reflectFee(rFee, rBurn, rCharity, tFee, tBurn, tCharity);
    emit Transfer(sender, recipient, tTransferAmount);
}

function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tCharity) = _getValues(tAmount);
    uint256 rBurn =  tBurn.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);
    _excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);        
    _sendToCharity(tCharity, sender);
    _reflectFee(rFee, rBurn, rCharity, tFee, tBurn, tCharity);
    emit Transfer(sender, recipient, tTransferAmount);
}

function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tCharity) = _getValues(tAmount);
    uint256 rBurn =  tBurn.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);
    _excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);
    _sendToCharity(tCharity, sender);
    _reflectFee(rFee, rBurn, rCharity, tFee, tBurn, tCharity);
    emit Transfer(sender, recipient, tTransferAmount);
}

function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tCharity) = _getValues(tAmount);
    uint256 rBurn =  tBurn.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);    
    _bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);  
    _sendToCharity(tCharity, sender);
    _reflectFee(rFee, rBurn, rCharity, tFee, tBurn, tCharity);
    emit Transfer(sender, recipient, tTransferAmount);
}


function _reflectFee(uint256 rFee, uint256 rBurn, uint256 rCharity, uint256 tFee, uint256 tBurn, uint256 tCharity) private {
    _rTotal = _rTotal.sub(rFee).sub(rBurn).sub(rCharity);
    _tFeeTotal = _tFeeTotal.add(tFee);
    _tBurnTotal = _tBurnTotal.add(tBurn);
    _tCharityTotal = _tCharityTotal.add(tCharity);
    _tTotal = _tTotal.sub(tBurn);
}