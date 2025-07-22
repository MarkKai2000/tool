function approveToken(address token, address spender, uint _amount) public returns (bool) {
    IERC20(token).safeApprove(spender, _amount);
    return true;
}

