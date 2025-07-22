function 0xb5863c10(address varg0) public payable { 
    require(4 + (msg.data.length - 4) - 4 >= 32);
    require(varg0 == varg0);
    stor_0_0_19 = varg0;
    owner_1_0_19 = msg.sender;
    owner_2_0_19 = msg.sender;
    stor_3 = 0x2a1766f5d000;
}

function 0x925d400c(uint256 varg0) public payable { 
    require(4 + (msg.data.length - 4) - 4 >= 32);
    0xcac(varg0);
    require(msg.sender == owner_1_0_19, Error('You are not admin'));
    stor_3 = varg0;
    return varg0;
}
