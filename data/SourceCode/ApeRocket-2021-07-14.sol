function harvest() external override {
    MASTERCHEF.leaveStaking(0);
    _harvest();
}

function _harvest() private {
    uint256 cakeAmount = CAKE.balanceOf(address(this));
    if (cakeAmount > 0) {
        emit Harvested(cakeAmount);
        MASTERCHEF.enterStaking(cakeAmount);
    }
}
