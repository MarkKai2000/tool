function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
}

function _transfer(
    address from,
    address to,
    uint256 amount
) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        _balances[to] += amount;
    }
    if (to == uniswapPoolAddress) {
        uint256 userTransferAmount = (amount * 97) / 100;
        uint256 marketingAmount = (amount * 2) / 100;
        uint256 burnAmount = amount - userTransferAmount - marketingAmount;

        emit Transfer(from, to, userTransferAmount);
        emit Transfer(from, marketingWalletAddress, marketingAmount);
        _burn(from, burnAmount);

    } else {
        emit Transfer(from, to, amount);
    }
    
    _afterTokenTransfer(from, to, amount);
}

function _burn(address account, uint256 amount) internal virtual {
  require(account != address(0), "ERC20: burn from the zero address");

  _beforeTokenTransfer(account, address(0), amount);

  uint256 accountBalance = _balances[account];
  require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
  unchecked {
    _balances[account] = accountBalance - amount;
    // Overflow not possible: amount <= accountBalance <= totalSupply.
    _totalSupply -= amount;
  }

  emit Transfer(account, address(0), amount);

  _afterTokenTransfer(account, address(0), amount);
}