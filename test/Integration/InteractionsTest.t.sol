//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;


import {Test,console} from "forge-std/Test.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test{
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant  SEND_VALUE=0.1 ether; //1e17
    uint256 constant  STARTING_BALANCE  =  10  ether; //this balance is for the USER

    function setUp() external{
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }
    

    function testUserCanFundInteractions() public{
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}