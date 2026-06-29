// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {MerkleAirdropToken} from "../src/MerkleAirdropToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract MerkleAirdropTest is Test {

    MerkleAirdropToken airdropToken;
    MerkleAirdrop airdrop;
    bytes32 public constant ROOT_HASH = 0xe8fc650625054774dfabac318860e854eabe5c1b6786e8341abc1fd1eaa7e5c5;
    address user;
    address thirdParty;
    uint256 userPrivKey;
    uint256 constant CLAIM_AMOUNT = 25 * 1e18;
    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [proof1, proof2];

    function setUp() public {
        // Deploy using the deployment script
        DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
        (airdrop, airdropToken) = deployer.deployMerkleAirdrop();

        // create predictable address and private key from the provided name in the cheatcode. i.e.,
        // the name 'whitelisted name'.
        // Once the address is known, it needs to be modified or added as one of the
        // `GenerateInput.s.sol` script addresses so that the
        // user above is part of merkle tree generated and also has proofs.
        (user, userPrivKey) = makeAddrAndKey("whitelisted user");
        // An address that performs claims using signatures of other users
        thirdParty = makeAddr("Third party user");
        vm.label(thirdParty, "ThirdParty");
        // log the value to paste it into input.json. Then check the root and modify accordingly on test
        console.log("The generated user address is: ", user);
    }

    function test__EligibleWhitelistedUsersCanClaimTokensSuccessfully() public {
        // Claiming for the user declared in this test contract.
        // Starting balance of user should be zero
        uint256 startingBal = airdropToken.balanceOf(user);

        // the deployment script already minted tokens to the airdrop contract
        // Now user claim
        vm.prank(user);
        // Normal claims without signatures pass zero values for signature
        airdrop.claim(user, CLAIM_AMOUNT, PROOF, 0, bytes32(0), bytes32(0));

        // User's balance should increase by `CLAIM_AMOUNT`
        uint256 endingBal = airdropToken.balanceOf(user);

        assertEq(endingBal - startingBal, CLAIM_AMOUNT);
    }

    function test__ThirdPartyUsersCanClaimOnBehalfOfWhitelistedUsersUsingSignatures() public {
        // Thirdparty claiming on behalf of the user declared in this test contract.
        // Starting balance of user should be zero
        uint256 startingBal = airdropToken.balanceOf(user);

        // construct an hash/digest
        bytes32 messageDigest = airdrop.getMessageDigest(user, CLAIM_AMOUNT);

        // User signs the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, messageDigest);

        // The Thirdparty then calls claim using the signature
        vm.prank(thirdParty);
        // Normal claims without signatures pass zero values for signature
        airdrop.claim(user, CLAIM_AMOUNT, PROOF, v, r, s);

        // User's balance should increase by `CLAIM_AMOUNT`
        uint256 endingBal = airdropToken.balanceOf(user);

        assertEq(endingBal - startingBal, CLAIM_AMOUNT);
    }

}
