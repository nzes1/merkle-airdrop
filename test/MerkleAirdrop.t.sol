// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {MerkleAirdropToken} from "../src/MerkleAirdropToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract MerkleAirdropTest is Test {

    MerkleAirdropToken airdropToken;
    MerkleAirdrop airdrop;
    bytes32 public constant ROOT_HASH = 0xe8fc650625054774dfabac318860e854eabe5c1b6786e8341abc1fd1eaa7e5c5;
    address user;
    uint256 userPrivKey;
    uint256 constant CLAIM_AMOUNT = 25 * 1e18;
    uint256 constant MINT_AMOUNT = 200e18;
    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [proof1, proof2];

    function setUp() public {
        airdropToken = new MerkleAirdropToken();
        airdrop = new MerkleAirdrop(ROOT_HASH, airdropToken);

        // create predictable address and private key from the provided name in the cheatcode. i.e.,
        // the name 'whitelisted name'.
        // Once the address is known, it needs to be modified or added as one of the
        // `GenerateInput.s.sol` script addresses so that the
        // user above is part of merkle tree generated and also has proofs.
        (user, userPrivKey) = makeAddrAndKey("whitelisted user");
        // log the value to paste it into input.json. Then check the root and modify accordingly on test
        console.log("The generated user address is: ", user);
    }

    function test__EligibleWhitelistedUsersCanClaimTokensSuccessfully() public {
        // Claiming for the user declared in this test contract.
        // Starting balance of user should be zero
        uint256 startingBal = airdropToken.balanceOf(user);

        // Before allowing the user to claim, the Merkle Airdrop contract address needs to have some tokens
        // The owner is the default foundry mdg,sender thus no need to change context
        airdropToken.mint(address(airdrop), MINT_AMOUNT);

        // Now user cllaim
        vm.prank(user);
        airdrop.claim(user, CLAIM_AMOUNT, PROOF);

        // User's balance should increase by `CLAIM_AMOUNT`
        uint256 endingBal = airdropToken.balanceOf(user);
    }

}
