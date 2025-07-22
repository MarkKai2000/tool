function performOperations(
    uint8[] calldata actions,
    uint256[] calldata values,
    bytes[] calldata datas
) external payable whenNotPaused returns (uint256 value1, uint256 value2) {
    OperationStatus memory status;
    uint256 actionsLength = actions.length;
    for (uint256 i = 0; i < actionsLength; i++) {
        uint8 action = actions[i];
        if (!status.hasAccrued && action < 10) {
            accumulate();
            status.hasAccrued = true;
        }
        if (action == Constants.OPERATION_ADD_COLLATERAL) {
            (int256 share, address to, bool skim) = abi.decode(
                datas[i],
                (int256, address, bool)
            );
            depositCollateral(to, skim, _num(share, value1, value2));
        } else if (action == Constants.OPERATION_REPAY) {
            (int256 part, address to, bool skim) = abi.decode(
                datas[i],
                (int256, address, bool)
            );
            _repay(to, skim, _num(part, value1, value2));
        } else if (action == Constants.OPERATION_REMOVE_COLLATERAL) {
            (int256 share, address to) = abi.decode(
                datas[i],
                (int256, address)
            );
            _withdrawCollateral(to, _num(share, value1, value2));
            status.needsSolvencyCheck = true;
        } else if (action == Constants.OPERATION_BORROW) {
            (int256 amount, address to) = abi.decode(
                datas[i],
                (int256, address)
            );
            (value1, value2) = _borrow(to, _num(amount, value1, value2));
            status.needsSolvencyCheck = true;
        } else if (action == Constants.OPERATION_UPDATE_PRICE) {
            (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(
                datas[i],
                (bool, uint256, uint256)
            );
            (bool updated, uint256 rate) = updatePrice();
            require(
                (!must_update || updated) &&
                    rate > minRate &&
                    (maxRate == 0 || rate < maxRate),
                "Chamber: rate not ok"
            );
        } else if (action == Constants.OPERATION_BENTO_SETAPPROVAL) {
            (
                address user,
                address _masterContract,
                bool approved,
                uint8 v,
                bytes32 r,
                bytes32 s
            ) = abi.decode(
                    datas[i],
                    (address, address, bool, uint8, bytes32, bytes32)
                );
            bentoBox.setMasterContractApproval(
                user,
                _masterContract,
                approved,
                v,
                r,
                s
            );
        } else if (action == Constants.OPERATION_BENTO_DEPOSIT) {
            (value1, value2) = _bentoDeposit(
                datas[i],
                values[i],
                value1,
                value2
            );
        } else if (action == Constants.OPERATION_BENTO_WITHDRAW) {
            (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
        } else if (action == Constants.OPERATION_BENTO_TRANSFER) {
            (IERC20 token, address to, int256 share) = abi.decode(
                datas[i],
                (IERC20, address, int256)
            );
            bentoBox.transfer(
                token,
                msg.sender,
                to,
                _num(share, value1, value2)
            );
        } else if (action == Constants.OPERATION_BENTO_TRANSFER_MULTIPLE) {
            (IERC20 token, address[] memory tos, uint256[] memory shares) = abi
                .decode(datas[i], (IERC20, address[], uint256[]));
            bentoBox.transferMultiple(token, msg.sender, tos, shares);
        } else if (action == Constants.OPERATION_CALL) {
            (bytes memory returnData, uint8 returnValues) = _call(
                values[i],
                datas[i],
                value1,
                value2
            );

            if (returnValues == 1) {
                (value1) = abi.decode(returnData, (uint256));
            } else if (returnValues == 2) {
                (value1, value2) = abi.decode(returnData, (uint256, uint256));
            }
        } else if (action == Constants.OPERATION_GET_REPAY_SHARE) {
            int256 part = abi.decode(datas[i], (int256));
            value1 = bentoBox.toShare(
                senUSD,
                totalBorrow.toElastic(_num(part, value1, value2), true),
                true
            );
        } else if (action == Constants.OPERATION_GET_REPAY_PART) {
            int256 amount = abi.decode(datas[i], (int256));
            value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
        } else if (action == Constants.OPERATION_LIQUIDATE) {
            _operationLiquidate(datas[i]);
        } else {
            (
                bytes memory returnData,
                uint8 returnValues,
                OperationStatus memory returnStatus
            ) = _extraOperation(
                    action,
                    status,
                    values[i],
                    datas[i],
                    value1,
                    value2
                );
            status = returnStatus;

            if (returnValues == 1) {
                (value1) = abi.decode(returnData, (uint256));
            } else if (returnValues == 2) {
                (value1, value2) = abi.decode(returnData, (uint256, uint256));
            }
        }
    }

    if (status.needsSolvencyCheck) {
        (, uint256 _exchangeRate) = updatePrice();
        require(
            _isSolvent(msg.sender, _exchangeRate),
            "Chamber: user insolvent"
        );
    }
}

function _call(
    uint256 value,
    bytes memory data,
    uint256 value1,
    uint256 value2
) internal whenNotPaused returns (bytes memory, uint8) {
    (
        address callee,
        bytes memory callData,
        bool useValue1,
        bool useValue2,
        uint8 returnValues
    ) = abi.decode(data, (address, bytes, bool, bool, uint8));

    if (useValue1 && !useValue2) {
        callData = abi.encodePacked(callData, value1);
    } else if (!useValue1 && useValue2) {
        callData = abi.encodePacked(callData, value2);
    } else if (useValue1 && useValue2) {
        callData = abi.encodePacked(callData, value1, value2);
    }

    require(!blacklisted[callee], "Chamber: can't call");

    (bool success, bytes memory returnData) = callee.call{value: value}(
        callData
    );
    require(success, "Chamber: call failed");
    return (returnData, returnValues);
}
