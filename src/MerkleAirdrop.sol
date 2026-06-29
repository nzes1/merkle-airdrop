//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop is EIP712 {

    using SafeERC20 for IERC20;

    // Root Hash and Airdrop token
    bytes32 private immutable i_RootHash;

    IERC20 private immutable i_airdropToken;

    // Claim status
    mapping(address account => bool claimed) private s_hasClaimed;

    // Airdrop claim message type hash
    bytes32 private constant AIRDROP_CLAIM_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    // struct for EIP-712 format claims using signatures
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    // Events
    event MerkleAirdrop__Claimed(address indexed user, uint256 amount);

    // Errors
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    constructor(bytes32 _merkleRootHash, IERC20 _airdropToken) EIP712("Merkle Airdrop", "1") {
        i_RootHash = _merkleRootHash;
        i_airdropToken = _airdropToken;
    }

    // Allowlist addresses claim function
    function claim(
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        // Ensure no double claims
        if (s_hasClaimed[_account]) revert MerkleAirdrop__AlreadyClaimed();

        // Make signatures optional so that normal claims still work
        if (v != 0) {
            // If claiming using signature, check the signature validity first
            if (!_isValidSignature(_account, getMessageDigest(_account, _amount), v, r, s)) {
                revert MerkleAirdrop__InvalidSignature();
            }
        }

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

    function getMessageDigest(address _account, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(AIRDROP_CLAIM_TYPEHASH, AirdropClaim({account: _account, amount: _amount})))
        );
    }

    function _isValidSignature(
        address _account,
        bytes32 _digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(_digest, v, r, s);
        return actualSigner == _account;
    }

}
