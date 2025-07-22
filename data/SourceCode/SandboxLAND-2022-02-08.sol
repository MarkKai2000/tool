function _burn(address from, address owner, uint256 id) public {
    require(from == owner, "not owner");
    _owners[id] = 2 ** 160; // cannot mint it again
    _numNFTPerAddress[from]--;
    emit Transfer(from, address(0), id);
}
