// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AidiStaking {
    using SafeERC20 for IERC20;

    struct StakedToken {
        uint256 amount;
        uint256 startTime;
        uint256 claimTime;
        bool active;
    }

    struct UnstakedToken {
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    mapping(address => StakedToken[]) public stakes;
    mapping(address => UnstakedToken[]) public unstakedInfo;

    IERC20 public token;
    address public owner;
    uint256 public rewardPercentPerYear = 12; // 12% per year
    uint256 public secondsPerDay = 86400; // 24*60*60 secs = 86400 secs =  one day
    uint256 public lockPeriod = 16; // 16 days

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    event EventStaked(address by, uint256 amount);
    event EventUnstaked(address by, uint256 amount);
    event EventClaimReward(address by, uint256 amount);
    event EventSetLockPeriod(address by, uint256 newLockPeriod);
    event EventSetRewardPercent(address by, uint256 newRewardPercent);
    event EventSetSecondsPerDay(address by, uint256 newSecondsPerDay);
    event EventTransferOwnership(
        address indexed previousOwner,
        address indexed newOwner
    );
    event EventSetRewardTokenAddress(address by, address token);
    event EventWithdrawUnstaked(address by, uint256 amount);
    event EventRecoverTokens(address by, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        stakes[msg.sender].push(StakedToken(amount, block.timestamp, 0, true));
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit EventStaked(msg.sender, amount);
    }

    function unstake(uint256 index) external {
        require(stakes[msg.sender].length > index, "Invalid index");

        StakedToken storage userStake = stakes[msg.sender][index];
        require(userStake.active, "No active stake");

        unstakedInfo[msg.sender].push(
            UnstakedToken(
                userStake.amount,
                block.timestamp + (lockPeriod * secondsPerDay),
                false
            )
        );

        userStake.active = false;
        emit EventUnstaked(msg.sender, userStake.amount);
    }

    function withdrawUnstakedTokens(uint256 index) external {
        require(unstakedInfo[msg.sender].length > index, "Invalid index");

        UnstakedToken storage unstakedToken = unstakedInfo[msg.sender][index];
        require(!unstakedToken.withdrawn, "Token has already been withdrawn");
        require(
            block.timestamp >= unstakedToken.unlockTime,
            "Token is still locked"
        );

        require(token.balanceOf(address(this)) >= unstakedToken.amount, "Insufficient contract balance");

        unstakedToken.withdrawn = true;
        token.safeTransfer(msg.sender, unstakedToken.amount);

        emit EventWithdrawUnstaked(msg.sender, unstakedToken.amount);
    }

    function claimReward() external {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            totalReward += calculateReward(msg.sender, i);
        }
        require(token.balanceOf(address(this)) >= totalReward, "Insufficient contract balance");
        token.transfer(msg.sender, totalReward);

        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            if(stakes[msg.sender][i].active) {
                stakes[msg.sender][i].claimTime = block.timestamp;
            }

        }
        emit EventClaimReward(msg.sender, totalReward);
    }

    function getTotalClaimableRewards(address user) external view returns (uint256) {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < stakes[user].length; i++) {
            totalReward += calculateReward(user, i);
        }

        return totalReward;
    }

    function calculateReward(address user, uint256 index) public view returns (uint256) {
        StakedToken memory userStake = stakes[user][index];
        if (!userStake.active) return 0;

        uint256 stakeDuration;
        if (userStake.claimTime == 0){
            stakeDuration = block.timestamp - userStake.startTime;
        }
        else{
            stakeDuration = block.timestamp - userStake.claimTime;
        }

        uint256 reward = (userStake.amount * rewardPercentPerYear * stakeDuration) / (secondsPerDay * 365 * 100);

        return reward;
    }

    function setLockPeriod(uint256 lockDays) external onlyOwner {
        require(lockDays > 0, "Lock period must be greater than zero");

        lockPeriod = lockDays;
        emit EventSetLockPeriod(msg.sender, lockDays);
    }

    function setSecondsPerDay(uint256 _secondsPerDay) external onlyOwner {
        require(
            _secondsPerDay > 0,
            "Seconds per day must be greater than zero"
        );
        secondsPerDay = _secondsPerDay;

        emit EventSetSecondsPerDay(msg.sender, _secondsPerDay);
    }

    function setRewardPercentPerYear(uint256 percent) external onlyOwner {
        require(percent > 0, "Reward percent must be greater than zero");
        rewardPercentPerYear = percent;

        emit EventSetRewardPercent(msg.sender, percent);
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        token = IERC20(tokenAddress);
        emit EventSetRewardTokenAddress(msg.sender, tokenAddress);
    }
    
    function getStakedTokensInfo(address user) external view returns (StakedToken[] memory) {
        return stakes[user];
    }

    function getTotalStakedAmount(address user) external view returns (uint256) {
        uint256 totalStakedAmount = 0;
        StakedToken[] storage userStakes = stakes[user];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].active) {
                totalStakedAmount += userStakes[i].amount;
            }
        }
        return totalStakedAmount;
    }

    function getTotalArrayStakedTokens(address user) external view returns (uint256) {
        return stakes[user].length;
    }

    function getRemainedLockTime(address user, uint256 index) external view returns (uint256) {
        require(unstakedInfo[user].length > index, "Invalid index");

        UnstakedToken storage userUnstake = unstakedInfo[user][index];
        require(!userUnstake.withdrawn, "No active unstake");

        if (block.timestamp < userUnstake.unlockTime) {
            return userUnstake.unlockTime - block.timestamp;
        }
        else{
            return 0;
        }
    }

    function getUnstakedTokensInfo(address user) external view returns (UnstakedToken[] memory) {
        return unstakedInfo[user];
    }

    function getTotalAmountOfUnstakedTokens(address user) external view returns (uint256) {
        uint256 totalAmount = 0;
        UnstakedToken[] storage userUnstakedTokens = unstakedInfo[user];
        for (uint256 i = 0; i < userUnstakedTokens.length; i++) {
            if (!userUnstakedTokens[i].withdrawn) {
                totalAmount += userUnstakedTokens[i].amount;
            }
        }
        return totalAmount;
    }

    function getTotalArrayUnstakedTokens(address user) external view returns (uint256) {
        return unstakedInfo[user].length;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");

        emit EventTransferOwnership(owner, newOwner);
        owner = newOwner;
    }

    function recoverTokens() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.safeTransfer(owner, balance);

        emit EventRecoverTokens(owner, balance);
    }
}
