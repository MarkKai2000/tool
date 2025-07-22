contract Authorization is Ownable {
    bytes32 private constant NAME_SLOT =
        0x7320715e23a405b30bfe5ed8f0781f194fa396c23546626bf8c46dcb790e6597;
    // 0x25aaa441b6cac9c2f49d8d012ccc517de4215e056b0f63883f025af9b63efed1 = keccak256("R0AR MASTERCHEF");
    bytes32 private constant NAME_HASH =
        0x25aaa441b6cac9c2f49d8d012ccc517de4215e056b0f63883f025af9b63efed1;

    constructor() public {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(NAME_SLOT, NAME_HASH)
        }
    }
}
