function batchTransfer(
    address[] _receivers,
    uint256 _value
) public whenNotPaused returns (bool) {
    uint cnt = _receivers.length;
    uint256 amount = uint256(cnt) * _value; // 这里没有使用 SafeMath
    require(cnt > 0 && cnt <= 20);
    require(_value > 0 && balances[msg.sender] >= amount);

    balances[msg.sender] = balances[msg.sender].sub(amount); // 使用 SafeMath 减去 amount
    for (uint i = 0; i < cnt; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
}

// hack here
// SPDX-License-Identifier: MIT
pragma solidity ^0.4.19;

contract BECTest {
    uint256 _value = 2 ** 255;
    function mulTest() public constant returns (uint) {
        uint256 amount = 2 * _value;
        return amount;
    }
}
