
// ivesting function for staking
function invest(uint256 end_date, uint256 qty_ort) external whenNotPaused {
    require(qty_ort > 0, "amount cannot be 0");
    //transfer token to this smart contract
    stakeToken.approve(address(this), qty_ort);
    stakeToken.safeTransferFrom(msg.sender, address(this), qty_ort);
    //save their staking duration for further use
    if (end_date == 3) {
        end_staking[msg.sender] = block.timestamp + 90 days;
        duration[msg.sender] = 3;
    } else if (end_date == 6) {
        end_staking[msg.sender] = block.timestamp + 180 days;
        duration[msg.sender] = 6;
    } else if (end_date == 12) {
        end_staking[msg.sender] = block.timestamp + 365 days;
        duration[msg.sender] = 12;
    } else if (end_date == 24) {
        end_staking[msg.sender] = block.timestamp + 730 days;
        duration[msg.sender] = 24;
    }
    //calculate reward tokens  for further use
    uint256 check_reward = _Check_reward(duration[msg.sender], qty_ort) /
        1 ether;
    //save values in array
    tokens_staking.push(
        staking(
            msg.sender,
            qty_ort,
            end_staking[msg.sender],
            duration[msg.sender],
            true,
            check_reward
        )
    );
    //save array index in map
    uint256 lockId = tokens_staking.length - 1;
    userStake[msg.sender].push(lockId);

    emit Invest(
        msg.sender,
        lockId,
        end_staking[msg.sender],
        duration[msg.sender],
        qty_ort,
        check_reward
    );
}

//Reward Calculation
function _Check_reward(uint256 durations, uint256 balance)
    internal
    returns (uint256)
{
    total_percent2 = balance / 1 ether;
    //if user stakes token for 3 months
    if (durations == 3) {
        if (total_percent2 >= 10000 && total_percent2 < 40000) {
            total_percent = _Percentage(balance, 600000000000000000);
        } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
            total_percent = _Percentage(balance, 1200000000000000000);
        } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
            total_percent = _Percentage(balance, 1800000000000000000);
        } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
            total_percent = _Percentage(balance, 2400000000000000000);
        } else if (total_percent2 >= 100000) {
            total_percent = _Percentage(balance, 3000000000000000000);
        }
    } else if (durations == 6) {
        if (total_percent2 >= 10000 && total_percent2 < 40000) {
            total_percent = _Percentage(balance, 1600000000000000000);
        } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
            total_percent = _Percentage(balance, 3200000000000000000);
        } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
            total_percent = _Percentage(balance, 4800000000000000000);
        } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
            total_percent = _Percentage(balance, 6400000000000000000);
        } else if (total_percent2 >= 100000) {
            total_percent = _Percentage(balance, 8000000000000000000);
        }
    } else if (durations == 12) {
        if (total_percent2 >= 10000 && total_percent2 < 40000) {
            total_percent = _Percentage(balance, 4000000000000000000);
        } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
            total_percent = _Percentage(balance, 8000000000000000000);
        } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
            total_percent = _Percentage(balance, 12000000000000000000);
        } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
            total_percent = _Percentage(balance, 16000000000000000000);
        } else if (total_percent2 >= 100000) {
            total_percent = _Percentage(balance, 20000000000000000000);
        }
    } else if (durations == 24) {
        if (total_percent2 >= 10000 && total_percent2 < 40000) {
            total_percent = _Percentage(balance, 11200000000000000000);
        } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
            total_percent = _Percentage(balance, 22400000000000000000);
        } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
            total_percent = _Percentage(balance, 33600000000000000000);
        } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
            total_percent = _Percentage(balance, 44800000000000000000);
        } else if (total_percent2 >= 100000) {
            total_percent = _Percentage(balance, 56000000000000000000);
        }
    }
    return total_percent;
}
