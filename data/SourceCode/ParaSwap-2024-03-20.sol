// @inheritdoc IUniswapV3SwapCallback
function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
) external {
    uint256 uniswapV3FactoryAndFF = UNISWAP_V3_FACTORY_AND_FF;
    uint256 uniswapV3PoolInitCodeHash = UNISWAP_V3_POOL_INIT_CODE_HASH;
    address permit2Address = PERMIT_2;
    bool isPermit2 = data.length == 512;
    // Check if data length is greater than 160 bytes (1 pool)
    // We pass multiple pools in data when executing a multi-hop swapExactAmountOut
    if (data.length > 160 && !isPermit2) {
        // Initialize recursive variables
        address payer;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy payer address from calldata
            payer := calldataload(164)
        }

        // Recursive call swapExactAmountOut
        _callUniswapV3PoolsSwapExactAmountOut(
            amount0Delta > 0 ? -amount0Delta : -amount1Delta,
            data,
            payer
        );
    } else {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Token to send to the pool
            let token
            // Amount to send to the pool
            let amount
            // Pool address
            let poolAddress := caller()

            // Get free memory pointer
            let ptr := mload(64)

            // We need make sure the caller is a UniswapV3Pool deployed by the canonical UniswapV3Factory
            // 1. Prepare data for calculating the pool address
            // Store ff+factory address, Load token0, token1, fee from bytes calldata and store pool init code hash

            // Store 0xff + factory address (right padded)
            mstore(ptr, uniswapV3FactoryAndFF)

            // Store data offset + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE)
            let token0Offset := add(ptr, 21)

            // Copy token0, token1, fee to free memory pointer + 21 bytes (UNISWAP_V3_FACTORY_AND_FF SIZE) + 1 byte
            // (direction)
            calldatacopy(add(token0Offset, 1), add(data.offset, 65), 95)

            // 2. Calculate the pool address
            // We can do this by first calling the keccak256 function on the fetched values and then
            // calculating keccak256(abi.encodePacked(hex'ff', address(factory_address),
            // keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            // The first 20 bytes of the computed address are the pool address

            // Calculate keccak256(abi.encode(address(token0), address(token1), fee))
            mstore(token0Offset, keccak256(token0Offset, 96))
            // Store POOL_INIT_CODE_HASH
            mstore(add(token0Offset, 32), uniswapV3PoolInitCodeHash)
            // Calculate keccak256(abi.encodePacked(hex'ff', address(factory_address), keccak256(abi.encode(token0,
            // token1, fee)), POOL_INIT_CODE_HASH));
            mstore(ptr, keccak256(ptr, 85)) // 21 + 32 + 32

            // Get the first 20 bytes of the computed address
            let computedAddress := and(
                mload(ptr),
                0xffffffffffffffffffffffffffffffffffffffff
            )

            // Check if the caller matches the computed address (and revert if not)
            if xor(poolAddress, computedAddress) {
                mstore(
                    0,
                    0x48f5c3ed00000000000000000000000000000000000000000000000000000000
                ) // store the selector
                // (error InvalidCaller())
                revert(0, 4) // revert with error selector
            }

            // If the caller is the computed address, then we can safely assume that the caller is a UniswapV3Pool
            // deployed by the canonical UniswapV3Factory

            // 3. Transfer amount to the pool

            // Check if amount0Delta or amount1Delta is positive and which token we need to send to the pool
            if sgt(amount0Delta, 0) {
                // If amount0Delta is positive, we need to send amount0Delta token0 to the pool
                token := and(
                    calldataload(add(data.offset, 64)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
                amount := amount0Delta
            }
            if sgt(amount1Delta, 0) {
                // If amount1Delta is positive, we need to send amount1Delta token1 to the pool
                token := calldataload(add(data.offset, 96))
                amount := amount1Delta
            }

            // Based on the data passed to the callback, we know the fromAddress that will pay for the
            // swap, if it is this contract, we will execute the transfer() function,
            // otherwise, we will execute transferFrom()

            // Check if fromAddress is this contract
            let fromAddress := calldataload(164)

            switch eq(fromAddress, address())
            // If fromAddress is this contract, execute transfer()
            case 1 {
                // Prepare external call data
                mstore(
                    ptr,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                ) // store the
                // selector
                // (function transfer(address recipient, uint256 amount))
                mstore(add(ptr, 4), poolAddress) // store the recipient
                mstore(add(ptr, 36), amount) // store the amount
                let success := call(gas(), token, 0, ptr, 68, 0, 32) // call transfer
                if success {
                    switch returndatasize()
                    // check the return data size
                    case 0 {
                        success := gt(extcodesize(token), 0)
                    }
                    default {
                        success := and(
                            gt(returndatasize(), 31),
                            eq(mload(0), 1)
                        )
                    }
                }

                if iszero(success) {
                    mstore(
                        0,
                        0x1bbb4abe00000000000000000000000000000000000000000000000000000000
                    ) // store the
                    // selector
                    // (error CallbackTransferFailed())
                    revert(0, 4) // revert with error selector
                }
            }
            // If fromAddress is not this contract, execute transferFrom() or permitTransferFrom()
            default {
                switch isPermit2
                // If permit2 is not present, execute transferFrom()
                case 0 {
                    mstore(
                        ptr,
                        0x23b872dd00000000000000000000000000000000000000000000000000000000
                    ) // store the
                    // selector
                    // (function transferFrom(address sender, address recipient,
                    // uint256 amount))
                    mstore(add(ptr, 4), fromAddress) // store the sender
                    mstore(add(ptr, 36), poolAddress) // store the recipient
                    mstore(add(ptr, 68), amount) // store the amount
                    let success := call(gas(), token, 0, ptr, 100, 0, 32) // call transferFrom
                    if success {
                        switch returndatasize()
                        // check the return data size
                        case 0 {
                            success := gt(extcodesize(token), 0)
                        }
                        default {
                            success := and(
                                gt(returndatasize(), 31),
                                eq(mload(0), 1)
                            )
                        }
                    }
                    if iszero(success) {
                        mstore(
                            0,
                            0x1bbb4abe00000000000000000000000000000000000000000000000000000000
                        ) // store the
                        // selector
                        // (error CallbackTransferFailed())
                        revert(0, 4) // revert with error selector
                    }
                }
                // If permit2 is present, execute permitTransferFrom()
                default {
                    // Otherwise Permit2.permitTransferFrom
                    // Store function selector
                    mstore(
                        ptr,
                        0x30f28b7a00000000000000000000000000000000000000000000000000000000
                    )
                    // permitTransferFrom()
                    calldatacopy(add(ptr, 4), 292, 352) // Copy data to memory
                    mstore(add(ptr, 132), poolAddress) // Store pool address as recipient
                    mstore(add(ptr, 164), amount) // Store amount as amount
                    // Call permit2.permitTransferFrom and revert if call failed
                    if iszero(call(gas(), permit2Address, 0, ptr, 356, 0, 0)) {
                        mstore(
                            0,
                            0x6b836e6b00000000000000000000000000000000000000000000000000000000
                        ) // Store
                        // error selector
                        // error Permit2Failed()
                        revert(0, 4)
                    }
                }
            }
        }
    }
}
