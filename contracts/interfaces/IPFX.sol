// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

interface IPFX {
    /// @notice An event that is emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event that is emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice An event that is emitted when an account is included in fees as a sender
    event IncludedSrc(address account);

    /// @notice An event that is emitted when an account is included in fees as a recipient
    event IncludedDst(address account);

    /// @notice An event that is emitted when an account is excluded in fees as a sender
    event ExcludedSrc(address account);

    /// @notice An event that is emitted when an anccount is excluded in fees as a recipient
    event ExcludedDst(address account);

    /// @notice An event that is emitted when a new reflection fee is set
    event SetReflectionFee(uint96 _reflectionFee);

    /// @notice An event that is emitted when a new dev fee is set
    event SetDevFee(uint96 _devFee);

    /// @notice An event that is emitted when a new rewards threshold is set
    event SetRewardsThreshold(uint256 _rewardsThreshold);

    /// @notice An event that is emitted when a new reflection address is set
    event SetReflectionAddress(address _reflectionAddress);

    /// @notice An event that is emitted when a new dev address is set
    event SetDevAddress(address _devAddress);

    /// @notice An event that is emitted when reflecting starts
    event StartedReflecting();

    /// @notice An event that is emitted when reflecting stops
    event StoppedReflecting();

    /// @notice An event that is emitted when dev fees start
    event StartedDevFees();

    /// @notice An event that is emitted when dev fees stop
    event StoppedDevFees();

    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function rewardsThreshold() external view returns (uint256);

    function includeSrc(address account) external;

    function includeDst(address account) external;

    function excludeSrc(address account) external;

    function excludeDst(address account) external;

    function setReflectionFee(uint96 _reflectionFee) external;

    function setDevFee(uint96 _devFee) external;

    function setRewardsThreshold(uint256 _rewardsThreshold) external;

    function setReflectionAddress(address _reflectionAddress) external;

    function setDevAddress(address _devAddress) external;

    function startReflecting() external;

    function stopReflecting() external;

    function startDevFees() external;

    function stopDevFees() external;
}
