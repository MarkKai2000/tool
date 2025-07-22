function init(
    uint256 _start,
    uint256[] calldata _releasePeriods,
    uint256[] calldata _releasePercents,
    address _token
) external {
    require(_start > block.timestamp, "Vesting: should start in future");
    require(
        _releasePeriods.length == _releasePercents.length,
        "Vesting: Unequal arrays!"
    );
    require(
        _releasePercents.length != 0 && _releasePercents.length < 12,
        "Vesting: Incompatible percents count!"
    );
    require(
        _getArraySum(_releasePercents) == HUNDRED_PERCENT,
        "Vesting: The total percent of all releases is not equal to hundred percent!"
    );

    start = _start;
    initialized = true;
    token = IERC20(_token);
    releasePeriods = _releasePeriods;
    releasePercents = _releasePercents;
    finish = start.add(_getArraySum(_releasePeriods));

    _transferOwnership(msg.sender);
}
