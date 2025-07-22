function withdraw() {
    require(msg.sender.call.value(balances[msg.sender])());
    balances[msg.sender] = 0;
}
