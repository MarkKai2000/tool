// constructor - just pass on the owner array to the multiowned and  // the limit to daylimit
function initWallet(address[] _owners, uint _required, uint _daylimit) {
    initDaylimit(_daylimit);
    initMultiowned(_owners, _required);
}

function() payable {
    // just being sent some cash?
    if (msg.value > 0) Deposit(msg.sender, msg.value);
    else if (msg.data.length > 0) _walletLibrary.delegatecall(msg.data);
}
