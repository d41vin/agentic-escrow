// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ConditionalPayment.sol";

/**
 * @title Deploy
 * @notice Deploy ConditionalPayment contract to Arc testnet
 * @dev Usage:
 *   forge script script/Deploy.s.sol --rpc-url $ARC_RPC_URL --broadcast --private-key $PRIVATE_KEY
 *
 *   Environment variables:
 *   - ARC_RPC_URL: Arc testnet RPC (https://testnet-rpc.arc.network)
 *   - PRIVATE_KEY: Deployer private key
 *   - USDC_ADDRESS: USDC contract address on Arc testnet
 */
contract Deploy is Script {
    function run() external {
        // Get USDC address from environment (Arc testnet USDC)
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast();

        ConditionalPayment escrow = new ConditionalPayment(usdcAddress);

        console.log("ConditionalPayment deployed to:", address(escrow));
        console.log("USDC address:", usdcAddress);

        vm.stopBroadcast();
    }
}
