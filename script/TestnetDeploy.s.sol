// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

/************************** 
TESTNET DEPLOYMENT: Optimism Goerli
**************************/

contract TestnetDeploy is Script {
    // contract(s) being deployed
    
    // constructor arguments

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy contract(s)

        vm.stopBroadcast();
    }
}

/**
 * TO DEPLOY:
 *
 * To load the variables in the .env file
 * > source .env
 *
 * To deploy and verify our contract
 * > forge script script/TestnetDeploy.s.sol:TestnetDeploy --rpc-url $OPTIMISM_GOERLI_RPC_URL --broadcast --verify -vvvv
 */
