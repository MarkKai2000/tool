function transfer(
    address to,
    uint256 amount
) public virtual override returns (bool) {
    address owner = msg.sender;
    _spendAllowance(owner, to, 0);
    _transfer(owner, to, amount);
    if (pair == msg.sender) {
        _calulate(to, amount);
    }
    return true;
}
function _calulate(address to, uint256 amount) internal {
    uint256 h2obalance = balanceOf(address(this));
    uint256 rate = 0;

    if (h2obalance <= 20_000_000 * 10 ** 18) {
        rate = 1;
    } else if (h2obalance <= 40_000_000 * 10 ** 18) {
        rate = 2;
    } else if (h2obalance <= 60_000_000 * 10 ** 18) {
        rate = 3;
    } else if (h2obalance <= 80_000_000 * 10 ** 18) {
        rate = 4;
    } else if (h2obalance <= 100_000_000 * 10 ** 18) {
        rate = 5;
    }

    uint256 random = getRandomOnchain() % 2;
    if (random == 1) {
        IBEP20(_h2).mint(to, (amount * rate) / 100);
    } else if (random == 0) {
        IBEP20(_o2).mint(to, (amount * rate) / 100);
    }

    uint256 h2balance = IBEP20(_h2).balanceOf(to);
    uint256 o2balance = IBEP20(_o2).balanceOf(to);

    if (h2balance >= 10 * 10 ** 18 && o2balance >= 5 * 10 ** 18) {
        if (h2balance / 2 >= o2balance) {
            IBEP20(_o2).burn(to, o2balance);
            IBEP20(_h2).burn(to, o2balance * 2);

            uint256 amountto = o2balance;
            if (amountto >= h2balance) {
                amountto = h2balance;
            }

            _transfer(address(this), to, amountto);
        } else if (h2balance / 2 < o2balance / 2) {
            IBEP20(_o2).burn(to, h2balance / 2);
            IBEP20(_h2).burn(to, h2balance);

            uint256 amountto = h2balance / 2;
            if (amountto >= h2balance) {
                amountto = h2balance;
            }

            _transfer(address(this), to, amountto);
        }
    }
}
function getRandomOnchain() public view returns (uint256) {
    bytes32 randomBytes = keccak256(
        abi.encodePacked(
            block.timestamp,
            msg.sender,
            blockhash(block.number - 1)
        )
    );
    return uint256(randomBytes);
}
