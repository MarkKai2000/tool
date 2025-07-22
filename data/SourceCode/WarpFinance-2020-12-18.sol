function provideCollateral(uint256 _amount) public {
    require(
        LPToken.allowance(msg.sender, address(this)) >= _amount,
        "Vault must have enough allowance."
    );
    require(
        LPToken.balanceOf(msg.sender) >= _amount,
        "Must have enough LP to provide"
    );

    LPToken.transferFrom(msg.sender, address(this), _amount);
    collateralizedLP[msg.sender] += _amount;

    emit CollateralProvided(msg.sender, _amount);
}
