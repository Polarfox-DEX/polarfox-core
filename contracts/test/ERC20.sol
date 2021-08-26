pragma solidity =0.5.16;

import '../PolarfoxLiquidity.sol';

contract ERC20 is PolarfoxLiquidity {
    constructor(uint256 _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
