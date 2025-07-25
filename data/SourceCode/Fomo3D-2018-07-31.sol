/**
 * @dev generates a random number between 0-99 and checks to see if thats
 * resulted in an airdrop win
 * @return do we have a winner?
 */
function airdrop() private view returns (bool) {
    uint256 seed = uint256(
        keccak256(
            abi.encodePacked(
                (block.timestamp)
                    .add(block.difficulty)
                    .add(
                        (uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                            (now)
                    )
                    .add(block.gaslimit)
                    .add(
                        (uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (now)
                    )
                    .add(block.number)
            )
        )
    );
    if ((seed - ((seed / 1000) * 1000)) < airDropTracker_) return (true);
    else return (false);
}
