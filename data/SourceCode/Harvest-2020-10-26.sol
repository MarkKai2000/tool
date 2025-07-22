function _deposit(
    uint256 amount,
    address sender,
    address beneficiary
) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");
    if (address(strategy()) != address(0)) {
        require(IStrategy(strategy()).depositCheck(), "Too much arb");
    }
    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);
    IERC20(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, amount);
}
/**
 * Returns the cash balance across all users in this contract.
 */
function underlyingBalanceInVault() public view returns (uint256) {
    return ERC20(underlying()).balanceOf(address(this));
}

/**
 * Returns the current underlying (e.g., DAI's) balance together with
 * the invested amount (if DAI is invested elsewhere by the strategy).
 */
function underlyingBalanceWithInvestment() public view returns (uint256) {
    if (address(strategy()) == address(0)) {
        // initial state, when not set
        return underlyingBalanceInVault();
    }

    return
        underlyingBalanceInVault().add(
            Strategy(strategy()).investedUnderlyingBalance()
        );
}
contract Vault is ERC20, ERC20Detailed, IVault, Controllable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);

    IStrategy public strategy;
    IERC20 public underlying;
    uint256 public underlyingUnit;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public withdrawals;

    uint256 public vaultFractionToInvestNumerator;
    uint256 public vaultFractionToInvestDenominator;

    constructor(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    )
        ERC20Detailed(
            string(
                abi.encodePacked("FARM_", ERC20Detailed(_underlying).symbol())
            ),
            string(abi.encodePacked("f", ERC20Detailed(_underlying).symbol())),
            ERC20Detailed(_underlying).decimals()
        )
        Controllable(_storage)
    {
        underlying = IERC20(_underlying);
        require(
            _toInvestNumerator <= _toInvestDenominator,
            "cannot invest more than 100%"
        );
        require(_toInvestDenominator != 0, "cannot divide by 0");
        vaultFractionToInvestDenominator = _toInvestDenominator;
        vaultFractionToInvestNumerator = _toInvestNumerator;
        underlyingUnit =
            10 ** uint256(ERC20Detailed(address(underlying)).decimals());
    }
}
function underlyingBalanceInVault() public view returns (uint256) {
    return underlying.balanceOf(address(this));
}
function underlyingBalanceWithInvestment() public view returns (uint256) {
    if (address(strategy) == address(0)) {
        return underlyingBalanceInVault();
    } else {
        return
            underlyingBalanceInVault().add(
                strategy.investedUnderlyingBalance()
            );
    }
}
function getContributions(address holder) public view returns (uint256) {
    return contributions[holder];
}
function getWithdrawals(address holder) public view returns (uint256) {
    return withdrawals[holder];
}
