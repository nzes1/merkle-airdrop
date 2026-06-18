//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {

    using SafeERC20 for IERC20;

    // Root Hash and Airdrop token
    bytes32 private immutable i_RootHash;

    IERC20 private immutable i_airdropToken;

    // Claim status
    mapping(address account => bool claimed) private s_hasClaimed;

    // Events
    event MerkleAirdrop__Claimed(address indexed user, uint256 amount);

    // Errors
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    constructor(bytes32 _merkleRootHash, IERC20 _airdropToken) {
        i_RootHash = _merkleRootHash;
        i_airdropToken = _airdropToken;
    }

    // Allowlist addresses claim function
    function claim(address _account, uint256 _amount, bytes32[] calldata _merkleProof) external {
        // Ensure no double claims
        if (s_hasClaimed[_account]) revert MerkleAirdrop__AlreadyClaimed();
        // As per OpenZeppelin's JS Library for generating the tree that is compatible with this project
        // the leaf has to have the following characteristics as defined under the standard tree features here:
        // https://github.com/OpenZeppelin/merkle-tree#standard-merkle-trees
        // - The leaves are the result of ABI encoding a series of values.
        // - The hash used is Keccak256.
        // - The leaves are double hashed to prevent second preimage attacks. Note that this is an opinionated design
        // adopted by OpenZeppelin.
        // Thus a leaf for the account and amount claiming is:
        bytes32 leafHash = keccak256(bytes.concat(keccak256(abi.encode(_account, _amount))));

        // Verify the proof
        if (!MerkleProof.verify(_merkleProof, i_RootHash, leafHash)) revert MerkleAirdrop__InvalidProof();

        // Using CEI pattern
        s_hasClaimed[_account] = true;
        emit MerkleAirdrop__Claimed(_account, _amount);
        i_airdropToken.safeTransfer(_account, _amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_RootHash;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

}
