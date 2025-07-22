function buyJay(
    address[] calldata erc721TokenAddress,
    uint256[] calldata erc721Ids,
    address[] calldata erc1155TokenAddress,
    uint256[] calldata erc1155Ids,
    uint256[] calldata erc1155Amounts
) public payable {
    require(start, "Not started!");
    uint256 total = erc721TokenAddress.length;
    if (total != 0) buyJayWithERC721(erc721TokenAddress, erc721Ids);

    if (erc1155TokenAddress.length != 0)
        total = total.add(
            buyJayWithERC1155(
                erc1155TokenAddress,
                erc1155Ids,
                erc1155Amounts
            )
        );

    if (total >= 100)
        require(
            msg.value >= (total).mul(sellNftFeeEth).div(2),
            "You need to pay ETH more"
        );
    else
        require(
            msg.value >= (total).mul(sellNftFeeEth),
            "You need to pay ETH more"
        );

    _mint(msg.sender, ETHtoJAY(msg.value).mul(97).div(100));

    (bool success, ) = dev.call{value: msg.value.div(34)}("");
    require(success, "ETH Transfer failed.");

    nftsSold += total;

    emit Price(block.timestamp, JAYtoETH(1 * 10**18));
}

function buyJayWithERC721(
    address[] calldata _tokenAddress,
    uint256[] calldata ids
) internal {
    for (uint256 id = 0; id < ids.length; id++) {
        IERC721(_tokenAddress[id]).transferFrom(
            msg.sender,
            address(this),
            ids[id]
        );
    }
}