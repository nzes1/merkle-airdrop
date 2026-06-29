// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {MerkleAirdropToken} from "../src/MerkleAirdropToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMerkleAirdrop is Script {

    bytes32 private s_rootHash = 0xe8fc650625054774dfabac318860e854eabe5c1b6786e8341abc1fd1eaa7e5c5;
    uint256 private s_totalClaimAmount = 1000e18; // Each user claims 25 tokens as per the output.json file.

    function run() external returns (MerkleAirdrop, MerkleAirdropToken) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (MerkleAirdrop, MerkleAirdropToken) {
        vm.startBroadcast();
        MerkleAirdropToken airdropToken = new MerkleAirdropToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(s_rootHash, IERC20(address(airdropToken)));
        // Mint the MerkleAirdrop contract the tokens to be claimed
        airdropToken.mint(address(airdrop), s_totalClaimAmount);
        vm.stopBroadcast();

        return (airdrop, airdropToken);
    }

}
