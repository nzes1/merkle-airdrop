// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MerkleAirdropToken is ERC20, Ownable {

    constructor() ERC20("MerkleAirdropToken", "MAT") Ownable(msg.sender) {}

    /// A way for the owner to supply (mint) tokens to any address
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

}
