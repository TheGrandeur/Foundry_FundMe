//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;


import {Test,console} from "forge-std/Test.sol";
import {PriceConverter} from "../src/PriceConverter.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundmeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant  SEND_VALUE=0.1 ether; //1e17
    uint256 constant  STARTING_BALANCE  =  10  ether; //this balance is for the USER
    
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //we give 10 fake ether to the USER for the txn
    }

    function testMinimumDollarisFive() public view {
        assertEq(fundMe.minUsd(), 5e19);
        
    }

    function testOwnerisMessgSender() public view {
        console.log("Owner is ", fundMe.getOwner());
        console.log("Msg Sender is ", msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
        
    }

    function testPriceFeedVersionisAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public{
        vm.expectRevert();
        fundMe.fund();
        
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); // Next txns will be from USER aka makeAddr("User")
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddresstoAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundertoArrayofFunders() public{
        vm.prank(USER); // Next txns will be from USER aka makeAddr("User")
        fundMe.fund{value: SEND_VALUE}();
        address funders = fundMe.getFunders(0);
        assertEq(funders, USER);
    }

    modifier funded(){ //to reduce the code duplication, we can use this modifier
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function TestOnlyOwnerCanWithdraw() public funded{ //if we want to run this test, we need to fund the contract first
        
        vm.prank(USER);
        vm.expectRevert();
        
        fundMe.withdraw();

    }

    function testWithdrawWithSingleFunder() public funded{

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded{
        //Arrange
        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i<numberofFunders; i++){
            // vm.prank and vm.deal (both should be pass together)
            //address(i) (thats why we use uint160 instead of uint256)
            hoax(address(i), SEND_VALUE);
            //fund the  Fundme
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded{  //cheaper that previous testWithdrawFromMultipleFunders() function
        //Arrange
        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i<numberofFunders; i++){
            // vm.prank and vm.deal (both should be pass together)
            //address(i) (thats why we use uint160 instead of uint256)
            hoax(address(i), SEND_VALUE);
            //fund the  Fundme
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeBalance);
    }

    
}