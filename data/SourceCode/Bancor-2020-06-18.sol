function safeTransferFrom(
    IERC2OToken _token,
    address _from,
    address _to,
    uint256 _value
) public {
    execute(
        _token,
        abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value)
    );
}
