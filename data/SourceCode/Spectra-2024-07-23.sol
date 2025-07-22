function _dispatch(bytes1 _commandType, bytes calldata _inputs) internal {
    uint256 command = uint8(_commandType & Commands.COMMAND_TYPE_MASK);

    if (command == Commands.TRANSFER_FROM) {
        (address token, uint256 value) = abi.decode(
            _inputs,
            (address, uint256)
        );
        IERC20(token).safeTransferFrom(msgSender, address(this), value);
    } else if (command == Commands.TRANSFER_FROM_WITH_PERMIT) {
        (
            address token,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
                _inputs,
                (address, uint256, uint256, uint8, bytes32, bytes32)
            );
        try
            IERC20Permit(token).permit(
                msgSender,
                address(this),
                value,
                deadline,
                v,
                r,
                s
            )
        {
            // Permit executed successfully, proceed
        } catch {
            // Check allowance to see if permit was already executed
            uint256 allowance = IERC20(token).allowance(
                msgSender,
                address(this)
            );
            if (allowance < value) {
                revert PermitFailed();
            }
        }
        IERC20(token).safeTransferFrom(msgSender, address(this), value);
    } else if (command == Commands.TRANSFER) {
        (address token, address recipient, uint256 value) = abi.decode(
            _inputs,
            (address, address, uint256)
        );
        recipient = _resolveAddress(recipient);
        value = _resolveTokenValue(token, value);
        if (value != 0) {
            IERC20(token).safeTransfer(recipient, value);
        }
    } else if (command == Commands.CURVE_SWAP) {
        (
            address pool,
            uint256 i,
            uint256 j,
            uint256 amountIn,
            uint256 minAmountOut,
            address recipient
        ) = abi.decode(
                _inputs,
                (address, uint256, uint256, uint256, uint256, address)
            );
        // pool.coins(i) is the token to be swapped
        address token = ICurvePool(pool).coins(i);
        amountIn = _resolveTokenValue(token, amountIn);
        recipient = _resolveAddress(recipient);
        IERC20(token).forceApprove(pool, amountIn);
        ICurvePool(pool).exchange(
            i,
            j,
            amountIn,
            minAmountOut,
            false, // Do not use ETH
            recipient
        );
        IERC20(token).forceApprove(pool, 0);
    } else if (command == Commands.WRAP_VAULT_IN_4626_ADAPTER) {
        (
            address wrapper,
            uint256 vaultShares,
            address recipient,
            uint256 minWrapperShares
        ) = abi.decode(_inputs, (address, uint256, address, uint256));
        address vault = ISpectra4626Wrapper(wrapper).vaultShare();
        recipient = _resolveAddress(recipient);
        vaultShares = _resolveTokenValue(vault, vaultShares);
        IERC20(vault).forceApprove(wrapper, vaultShares);
        ISpectra4626Wrapper(wrapper).wrap(
            vaultShares,
            recipient,
            minWrapperShares
        );
        IERC20(vault).forceApprove(wrapper, 0);
    } else if (command == Commands.UNWRAP_VAULT_FROM_4626_ADAPTER) {
        (
            address wrapper,
            uint256 wrapperShares,
            address recipient,
            uint256 minVaultShares
        ) = abi.decode(_inputs, (address, uint256, address, uint256));
        recipient = _resolveAddress(recipient);
        wrapperShares = _resolveTokenValue(wrapper, wrapperShares);
        ISpectra4626Wrapper(wrapper).unwrap(
            wrapperShares,
            recipient,
            address(this),
            minVaultShares
        );
    } else if (command == Commands.DEPOSIT_ASSET_IN_IBT) {
        (address ibt, uint256 assets, address recipient) = abi.decode(
            _inputs,
            (address, uint256, address)
        );
        address asset = IERC4626(ibt).asset();
        assets = _resolveTokenValue(asset, assets);
        recipient = _resolveAddress(recipient);
        IERC20(asset).forceApprove(ibt, assets);
        IERC4626(ibt).deposit(assets, recipient);
        IERC20(asset).forceApprove(ibt, 0);
    } else if (command == Commands.DEPOSIT_ASSET_IN_PT) {
        (
            address pt,
            uint256 assets,
            address ptRecipient,
            address ytRecipient,
            uint256 minShares
        ) = abi.decode(_inputs, (address, uint256, address, address, uint256));
        address asset = IPrincipalToken(pt).underlying();
        assets = _resolveTokenValue(asset, assets);
        ptRecipient = _resolveAddress(ptRecipient);
        ytRecipient = _resolveAddress(ytRecipient);
        bool isRegisteredPT = IRegistry(registry).isRegisteredPT(pt);
        if (isRegisteredPT) {
            _ensureApproved(asset, pt, assets);
        } else {
            IERC20(asset).forceApprove(pt, assets);
        }
        IPrincipalToken(pt).deposit(
            assets,
            ptRecipient,
            ytRecipient,
            minShares
        );
        if (!isRegisteredPT) {
            IERC20(asset).forceApprove(pt, 0);
        }
    } else if (command == Commands.DEPOSIT_IBT_IN_PT) {
        (
            address pt,
            uint256 ibts,
            address ptRecipient,
            address ytRecipient,
            uint256 minShares
        ) = abi.decode(_inputs, (address, uint256, address, address, uint256));
        address ibt = IPrincipalToken(pt).getIBT();
        ibts = _resolveTokenValue(ibt, ibts);
        ptRecipient = _resolveAddress(ptRecipient);
        ytRecipient = _resolveAddress(ytRecipient);
        bool isRegisteredPT = IRegistry(registry).isRegisteredPT(pt);
        if (isRegisteredPT) {
            _ensureApproved(ibt, pt, ibts);
        } else {
            IERC20(ibt).forceApprove(pt, ibts);
        }
        IPrincipalToken(pt).depositIBT(
            ibts,
            ptRecipient,
            ytRecipient,
            minShares
        );
        if (!isRegisteredPT) {
            IERC20(ibt).forceApprove(pt, 0);
        }
    } else if (command == Commands.REDEEM_IBT_FOR_ASSET) {
        (address ibt, uint256 shares, address recipient) = abi.decode(
            _inputs,
            (address, uint256, address)
        );
        shares = _resolveTokenValue(ibt, shares);
        recipient = _resolveAddress(recipient);
        IERC4626(ibt).redeem(shares, recipient, address(this));
    } else if (command == Commands.REDEEM_PT_FOR_ASSET) {
        (address pt, uint256 shares, address recipient, uint256 minAssets) = abi
            .decode(_inputs, (address, uint256, address, uint256));
        shares = _resolveTokenValue(pt, shares);
        recipient = _resolveAddress(recipient);
        IPrincipalToken(pt).redeem(shares, recipient, address(this), minAssets);
    } else if (command == Commands.REDEEM_PT_FOR_IBT) {
        (address pt, uint256 shares, address recipient, uint256 minIbts) = abi
            .decode(_inputs, (address, uint256, address, uint256));
        shares = _resolveTokenValue(pt, shares);
        recipient = _resolveAddress(recipient);
        IPrincipalToken(pt).redeemForIBT(
            shares,
            recipient,
            address(this),
            minIbts
        );
    } else if (command == Commands.FLASH_LOAN) {
        (address lender, address token, uint256 amount, bytes memory data) = abi
            .decode(_inputs, (address, address, uint256, bytes));
        if (!IRegistry(registry).isRegisteredPT(lender)) {
            revert InvalidFlashloanLender(lender);
        }
        flashloanLender = lender;
        IERC3156FlashLender(lender).flashLoan(
            IERC3156FlashBorrower(address(this)),
            token,
            amount,
            data
        );
        flashloanLender = address(0);
    } else if (command == Commands.CURVE_SPLIT_IBT_LIQUIDITY) {
        (
            address pool,
            uint256 ibts,
            address recipient,
            address ytRecipient,
            uint256 minPTShares
        ) = abi.decode(_inputs, (address, uint256, address, address, uint256));
        recipient = _resolveAddress(recipient);
        ytRecipient = _resolveAddress(ytRecipient);
        address ibt = ICurvePool(pool).coins(0);
        address pt = ICurvePool(pool).coins(1);
        ibts = _resolveTokenValue(ibt, ibts);
        uint256 ibtToDepositInPT = CurvePoolUtil.calcIBTsToTokenizeForCurvePool(
            ibts,
            pool,
            pt
        );
        if (ibtToDepositInPT != 0) {
            bool isRegisteredPT = IRegistry(registry).isRegisteredPT(pt);
            if (isRegisteredPT) {
                _ensureApproved(ibt, pt, ibtToDepositInPT);
            } else {
                IERC20(ibt).forceApprove(pt, ibtToDepositInPT);
            }
            IPrincipalToken(pt).depositIBT(
                ibtToDepositInPT,
                recipient,
                ytRecipient,
                minPTShares
            );
            if (!isRegisteredPT) {
                IERC20(ibt).forceApprove(pt, 0);
            }
        }
        if (recipient != address(this) && (ibts - ibtToDepositInPT) != 0) {
            IERC20(ibt).safeTransfer(recipient, ibts - ibtToDepositInPT);
        }
    } else if (command == Commands.CURVE_ADD_LIQUIDITY) {
        (
            address pool,
            uint256[2] memory amounts,
            uint256 min_mint_amount,
            address recipient
        ) = abi.decode(_inputs, (address, uint256[2], uint256, address));
        recipient = _resolveAddress(recipient);
        address ibt = ICurvePool(pool).coins(0);
        address pt = ICurvePool(pool).coins(1);
        amounts[0] = _resolveTokenValue(ibt, amounts[0]);
        amounts[1] = _resolveTokenValue(pt, amounts[1]);
        IERC20(ibt).forceApprove(pool, amounts[0]);
        IERC20(pt).forceApprove(pool, amounts[1]);
        ICurvePool(pool).add_liquidity(
            amounts,
            min_mint_amount,
            false,
            recipient
        );
        IERC20(ibt).forceApprove(pool, 0);
        IERC20(pt).forceApprove(pool, 0);
    } else if (command == Commands.CURVE_REMOVE_LIQUIDITY) {
        (
            address pool,
            uint256 lps,
            uint256[2] memory min_amounts,
            address recipient
        ) = abi.decode(_inputs, (address, uint256, uint256[2], address));
        recipient = _resolveAddress(recipient);
        address lpToken = ICurvePool(pool).token();
        lps = _resolveTokenValue(lpToken, lps);
        ICurvePool(pool).remove_liquidity(lps, min_amounts, false, recipient);
    } else if (command == Commands.CURVE_REMOVE_LIQUIDITY_ONE_COIN) {
        (
            address pool,
            uint256 lps,
            uint256 i,
            uint256 min_amount,
            address recipient
        ) = abi.decode(_inputs, (address, uint256, uint256, uint256, address));
        recipient = _resolveAddress(recipient);
        address lpToken = ICurvePool(pool).token();
        lps = _resolveTokenValue(lpToken, lps);
        ICurvePool(pool).remove_liquidity_one_coin(
            lps,
            i,
            min_amount,
            false,
            recipient
        );
    } else if (command == Commands.KYBER_SWAP) {
        (
            address kyberRouter,
            address tokenIn,
            uint256 amountIn,
            address tokenOut,
            ,
            bytes memory targetData
        ) = abi.decode(
                _inputs,
                (address, address, uint256, address, uint256, bytes)
            );
        if (tokenOut == Constants.ETH) {
            revert AddressError();
        }
        if (tokenIn == Constants.ETH) {
            if (msg.value != amountIn) {
                revert AmountError();
            }
            (bool success, ) = kyberRouter.call{value: msg.value}(targetData);
            if (!success) {
                revert CallFailed();
            }
        } else {
            amountIn = _resolveTokenValue(tokenIn, amountIn);
            IERC20(tokenIn).forceApprove(kyberRouter, amountIn);
            (bool success, ) = kyberRouter.call(targetData);
            if (!success) {
                revert CallFailed();
            }
            IERC20(tokenIn).forceApprove(kyberRouter, 0);
        }
    } else if (command == Commands.ASSERT_MIN_BALANCE) {
        (address token, address owner, uint256 minValue) = abi.decode(
            _inputs,
            (address, address, uint256)
        );
        owner = _resolveAddress(owner);
        uint256 balance = IERC20(token).balanceOf(owner);
        if (balance < minValue) {
            revert MinimumBalanceNotReached(token, owner, minValue, balance);
        }
    } else {
        revert InvalidCommandType(command);
    }
}

function execute(
    bytes calldata _commands,
    bytes[] calldata _inputs
) public payable override {
    uint256 numCommands = _commands.length;
    if (_inputs.length != numCommands) {
        revert LengthMismatch();
    }

    // Relying on msg.sender is problematic as it changes during a flash loan.
    // Thus, it's necessary to track who initiated the original Router execution.
    bool topLevel;
    if (msgSender == address(0)) {
        msgSender = msg.sender;
        topLevel = true;
    } else if (msg.sender != address(this)) {
        revert UnauthorizedReentrantCall();
    }

    // Loop through all given commands, execute them and pass along outputs as defined
    for (uint256 commandIndex; commandIndex < numCommands; ) {
        bytes1 command = _commands[commandIndex];
        bytes calldata input = _inputs[commandIndex];

        _dispatch(command, input);
        unchecked {
            commandIndex++;
        }
    }

    if (topLevel) {
        // top-level reset
        msgSender = address(0);
    }
}
