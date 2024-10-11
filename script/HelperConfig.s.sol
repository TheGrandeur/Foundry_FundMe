//SPDX-License-Identifier: MIT

//Deploy mocks when we are on a local chain
// Keep track of contracts address across different chains
// like, Sepolia ETH/USD has diffrent address 
//and Mainnet ETH/USD has diffrent address


pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig{
        address priceFeed; //ETH/USD price feed address
    }

    constructor(){
        if(block.chainid==11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else{
            activeNetworkConfig = getAnvilEthConfig();
        }
        
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory){

        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        // Deploy the mocks when we are on a local chain
        // Return the address of the mocks

        vm.startBroadcast();

        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        
        return anvilConfig;
    }


}
