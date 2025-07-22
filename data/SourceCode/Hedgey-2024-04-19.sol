function createLockedCampaign(
    bytes16 id,
    Campaign memory campaign,
    ClaimLockup memory claimLockup,
    Donation memory donation
) external nonReentrant {
    require(!usedIds[id], "in use");
    usedIds[id] = true;
    require(campaign.token != address(0), "0_address");
    require(campaign.manager != address(0), "0_manager");
    require(campaign.amount > 0, "0_amount");
    require(campaign.end > block.timestamp, "end error");
    require(campaign.tokenLockup != TokenLockup.Unlocked, "!locked");
    require(claimLockup.tokenLocker != address(0), "invalide locker");
    TransferHelper.transferTokens(
        campaign.token,
        msg.sender,
        address(this),
        campaign.amount + donation.amount
    );
    if (donation.amount > 0) {
        if (donation.start > 0) {
            SafeERC20.safeIncreaseAllowance(
                IERC20(campaign.token),
                donation.tokenLocker,
                donation.amount
            );
            ILockupPlans(donation.tokenLocker).createPlan(
                donationCollector,
                campaign.token,
                donation.amount,
                donation.start,
                donation.cliff,
                donation.rate,
                donation.period
            );
        } else {
            TransferHelper.withdrawTokens(
                campaign.token,
                donationCollector,
                donation.amount
            );
        }
        emit TokensDonated(
            id,
            donationCollector,
            campaign.token,
            donation.amount,
            donation.tokenLocker
        );
    }
    claimLockups[id] = claimLockup;
    SafeERC20.safeIncreaseAllowance(
        IERC20(campaign.token),
        claimLockup.tokenLocker,
        campaign.amount
    );
    campaigns[id] = campaign;
    emit ClaimLockupCreated(id, claimLockup);
    emit CampaignStarted(id, campaign);
}
function cancelCampaign(bytes16 campaignId) external nonReentrant {
    Campaign memory campaign = campaigns[campaignId];
    require(campaign.manager == msg.sender, "!manager");
    delete campaigns[campaignId];
    delete claimLockups[campaignId];
    TransferHelper.withdrawTokens(campaign.token, msg.sender, campaign.amount);
    emit CampaignCancelled(campaignId);
}
