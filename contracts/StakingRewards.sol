// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './interfaces/IStakingRewards.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPFX.sol';
import './interfaces/IPolarfoxLiquidity.sol';
import './libraries/RewardsDistributionRecipient.sol';
import './libraries/ReentrancyGuard.sol';
import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';
import './libraries/Math.sol';

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint public constant TOTAL_SUPPLY_DENOMINATOR = 10000000;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private totalSupply_;
    uint public topHoldersSupply;
    address public pfx;
    address[] public topHolders_; // Used by PFX token mechanics
    mapping(address => uint) public topHoldersIndex; // Used to avoid resorting to a loop when removing holders
    mapping(address => bool) public isTopHolder;
    mapping(address => uint256) private balances_;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _pfx
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        
        // Set the PFX address
        pfx = _pfx;

        // Set the top holder supply
        topHoldersSupply = 0;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function topHolders() external view returns (address[] memory) {
        return topHolders_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances_[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply_ == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply_)
            );
    }

    function earned(address account) public view returns (uint256) {
        return balances_[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        // Get the PFX rewards threshold
        uint256 rewardsThreshold = IPFX(pfx).rewardsThreshold();

        // Add to top holders if necessary
        if (!isTopHolder[msg.sender] && amount >= rewardsThreshold.mul(totalSupply_).div(TOTAL_SUPPLY_DENOMINATOR)) {
            // Mark the address as a top holder
            isTopHolder[msg.sender] = true;

            // Push the address at the end of the topHolders_ array
            topHoldersIndex[msg.sender] = topHolders_.length;
            topHolders_.push(msg.sender);

            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(amount);
        }

        // If the address already is a top holder
        else if (isTopHolder[msg.sender]) {
            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(amount);
        }

        balances_[msg.sender] = balances_[msg.sender].add(amount);

        // permit
        IPolarfoxLiquidity(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply_ = totalSupply_.add(amount);

        // Get the PFX rewards threshold
        uint256 rewardsThreshold = IPFX(pfx).rewardsThreshold();

        // Add to top holders if necessary
        if (!isTopHolder[msg.sender] && amount >= rewardsThreshold.mul(totalSupply_).div(TOTAL_SUPPLY_DENOMINATOR)) {
            // Mark the address as a top holder
            isTopHolder[msg.sender] = true;

            // Push the address at the end of the topHolders_ array
            topHoldersIndex[msg.sender] = topHolders_.length;
            topHolders_.push(msg.sender);

            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(amount);
        }

        // If the address already is a top holder
        else if (isTopHolder[msg.sender]) {
            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(amount);
        }

        balances_[msg.sender] = balances_[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        // Get the PFX rewards threshold
        uint256 rewardsThreshold = IPFX(pfx).rewardsThreshold();

        // Store the previous balance
        uint previousBalance = balances_[msg.sender];
        
        totalSupply_ = totalSupply_.sub(amount);
        balances_[msg.sender] = balances_[msg.sender].sub(amount);

        // Remove from top holders if necessary
        if (isTopHolder[msg.sender] && balances_[msg.sender] < rewardsThreshold.mul(totalSupply_).div(TOTAL_SUPPLY_DENOMINATOR)) {
            // Mark the address as not a top holder
            isTopHolder[msg.sender] = false;

            // Move the last address in the topHolders_ array in the place of the address we just removed
            topHolders_[topHoldersIndex[msg.sender]] = topHolders_[topHolders_.length-1];
            topHoldersIndex[topHolders_[topHolders_.length-1]] = topHoldersIndex[msg.sender];

            // Delete this address from the topHoldersIndex mapping
            delete topHoldersIndex[msg.sender];

            // Remove the last address from the topHolders_ array
            topHolders_.pop();

            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.sub(previousBalance);
        }

        // If the address still is a top holder after the withdrawal
        else if (isTopHolder[msg.sender]) {
            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.sub(amount);
        }

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balances_[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}