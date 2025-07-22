function withdrawStuckToken(
    IERC20 _token
) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 tokenBalance = _token.balanceOf(address(this));
    if (tokenBalance > 0) {
        _token.safeTransfer(_msgSender(), tokenBalance);
    }
}
