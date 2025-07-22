function burn(uint256 tokenId) external virtual {
    _burn(tokenId);
}

function _burn(uint256 tokenId) internal virtual {
    address from = ownerOf(tokenId);
    _beforeTokenTransfers(from, address(0), tokenId, 1);
    _burnedToken.set(tokenId);
    
    emit Transfer(from, address(0), tokenId);

    _afterTokenTransfers(from, address(0), tokenId, 1);
}