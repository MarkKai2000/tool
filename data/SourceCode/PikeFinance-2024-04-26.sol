function initialize(
    address _console,
    address _rng,
    address _vault,
    address _gameProvider,
    uint16 _minPos,
    uint16 _maxPos
) public nonPayable {
    require(msg.data.length - 4 == 192, "Invalid data length");
    uint256 v0 = stor_b_2_2;
    if (!stor_b_2_2) {
        v0 = (stor_b_1_1 < 1) ? 1 : 0;
    }
    if (!v0) {
        bool v3 = !this.code.size;
        if (!bool(this.code.size)) {
            v0 = (stor_b_1_1 < 1) ? 1 : 0;
        }
    }
    require(v0, "Initializable: contract is already initialized");
    stor_b_1_1 = 1;
    if (!stor_b_2_2) {
        stor_b_2_2 = 1;
    }
    _gateway = _console;
    owner_2_0_19 = _rng;
    _endpoint = _vault;
    stor_4_0_19 = _gameProvider;
    isActive =
        0x1 |
        ((bytes31(msg.sender << 40) & 0xffffffffffffffffffffffffffffffff00) |
            (_minPos << 8) |
            (_maxPos << 24) |
            (_isActive & 0xffffffffffffff00000000ff));

    _nativeAsset = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    if (!stor_b_2_2) {
        stor_b_2_2 = 0;
        emit Initialized();
    }
}
