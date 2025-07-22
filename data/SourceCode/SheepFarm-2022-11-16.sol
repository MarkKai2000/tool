function register(address neighbor) external initialized {
    address user = msg.sender;
    require(villages[user].timestamp == 0, "just new users");
    uint256 gems;
    totalVillages++;
    if (villages[neighbor].sheeps[0] > 0 && neighbor != manager) {
        gems += GEM_BONUS * 2;
    } else {
        neighbor = manager;
        gems += GEM_BONUS;
    }
    villages[neighbor].neighbors++;
    villages[user].neighbor = neighbor;
    villages[user].gems += gems;
    emit Newbie(msg.sender, gems);
}
function upgradeVillage(uint256 farmId) external initialized {
    require(farmId < 6, "Max 6 farm");
    address user = msg.sender;
    if (villages[user].sheeps[0] == 0) {
        require(farmId == 0, "Only first farm is available");
    }
    if (villages[user].farm < farmId) {
        villages[user].farm++;
        require(villages[user].farm == farmId, "farm is lock");
    }
    syncVillage(user);
    villages[user].sheeps[farmId]++;
    totalSheeps++;
    uint256 sheeps = villages[user].sheeps[farmId];
    villages[user].gems -= getUpgradePrice(farmId, sheeps) / denominator;
    villages[user].yield += getYield(farmId, sheeps);
    emit VillageUpgraded(
        msg.sender,
        villages[user].yield,
        villages[user].farm,
        block.timestamp
    );
}
function sellVillage() external initialized {
    collectMoney();
    address user = msg.sender;
    uint8[6] memory sheeps = villages[user].sheeps;
    totalSheeps -=
        sheeps[0] +
        sheeps[1] +
        sheeps[2] +
        sheeps[3] +
        sheeps[4] +
        sheeps[5];
    villages[user].money += villages[user].yield * 24 * 5;
    villages[user].sheeps = [0, 0, 0, 0, 0, 0];
    villages[user].yield = 0;
    villages[user].warehouse = 0;
    villages[user].truck = 0;
    villages[user].farm = 0;
    emit SellVillage(msg.sender, block.timestamp);
}
