// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;

import './interfaces/IPFX.sol';
import './interfaces/IPolarfoxLiquidity.sol';
import './libraries/SafeMath.sol';

contract PolarfoxLiquidity is IPolarfoxLiquidity {
    using SafeMath for uint256;

    string public constant name = 'Polarfox Liquidity';
    string public constant symbol = 'PFX-LP';
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY_DENOMINATOR = 10000000;
    uint256 public totalSupply;
    uint256 public topHoldersSupply;
    address public pfx;
    address[] public topHolders_; // Used by PFX token mechanics
    mapping(address => uint256) public topHoldersIndex; // Used to avoid resorting to a loop when removing holders
    mapping(address => bool) public isTopHolder;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _pfx) public {
        // Set the PFX address
        pfx = _pfx;

        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        // Set the top holder supply
        topHoldersSupply = 0;
    }

    function topHolders() external view returns (address[] memory) {
        return topHolders_;
    }

    function increaseBalance(address _address, uint256 value) private {
        // Get the PFX rewards threshold
        uint256 rewardsThreshold = IPFX(pfx).rewardsThreshold();

        // Increase balance
        balanceOf[_address] = balanceOf[_address].add(value);

        // Add to top holders if necessary
        if (!isTopHolder[_address] && balanceOf[_address] >= rewardsThreshold.mul(totalSupply).div(TOTAL_SUPPLY_DENOMINATOR)) {
            // Mark the address as a top holder
            isTopHolder[_address] = true;

            // Push the address at the end of the topHolders_ array
            topHoldersIndex[_address] = topHolders_.length;
            topHolders_.push(_address);

            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(balanceOf[_address]);
        }
        // If the address already is a top holder
        else if (isTopHolder[_address]) {
            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.add(value);
        }
    }

    function decreaseBalance(address _address, uint256 value) private {
        // Get the PFX rewards threshold
        uint256 rewardsThreshold = IPFX(pfx).rewardsThreshold();

        // Store the previous balance
        uint256 previousBalance = balanceOf[_address];

        // Decrease balance
        balanceOf[_address] = previousBalance.sub(value);

        // Remove from top holders if necessary
        if (isTopHolder[_address] && balanceOf[_address] < rewardsThreshold.mul(totalSupply).div(TOTAL_SUPPLY_DENOMINATOR)) {
            // Mark the address as not a top holder
            isTopHolder[_address] = false;

            // Move the last address in the topHolders_ array in the place of the address we just removed
            topHolders_[topHoldersIndex[_address]] = topHolders_[topHolders_.length - 1];
            topHoldersIndex[topHolders_[topHolders_.length - 1]] = topHoldersIndex[_address];

            // Delete this address from the topHoldersIndex mapping
            delete topHoldersIndex[_address];

            // Remove the last address from the topHolders_ array
            topHolders_.pop();

            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.sub(previousBalance);
        }
        // If the address still is a top holder after the withdrawal
        else if (isTopHolder[_address]) {
            // Update the total supply accordingly
            topHoldersSupply = topHoldersSupply.sub(value);
        }
    }

    function _mint(address to, uint256 value) internal {
        increaseBalance(to, value);
        totalSupply = totalSupply.add(value);

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        decreaseBalance(from, value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        decreaseBalance(from, value);
        increaseBalance(to, value);

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'Polarfox: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Polarfox: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
