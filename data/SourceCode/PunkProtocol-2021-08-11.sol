function initialize(
    address forge_,
    address token_,
    address cToken_,
    address comp_,
    address comptroller_,
    address uRouterV2_
) public {
    addToken(token_);
    setForge(forge_);
    _cToken = cToken_;
    _comp = comp_;
    _comptroller = comptroller_;
    _uRouterV2 = uRouterV2_;
}
