// We will fo here : Get funds from user, withdraw funds and set a minimun funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


library PriceConverter{

    function getprice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        //Address - ETH/USD - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI  
        (,int256 price,,,) = priceFeed.latestRoundData();
        //price of ETH in the terms of USD
        return uint256(price * 1e10);
    }

    function getConversionRate (uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        
        uint256 ethPrice = getprice(priceFeed);
        //(2000_000000000000000000 * 1000000000000000000) / 1e18
        //$2000 = 1ETH
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountinUsd;
    }

       

}

contract FundMe{
    using PriceConverter for uint256; // so uint256 get access to all the functions are in the PriceConverter

    uint256 public constant minUsd=50 * 1e18;
    address[] public s_funders ;

    mapping(address funders => uint256 amountFunded) private s_addressToAmountFunded;
    
    address private immutable owner; 
    AggregatorV3Interface private s_priceFeed;



    constructor(address priceFeed) {  //we use constructor for safety for withdraw function, is should only be execute by owner only
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {

        // msg.value.getConversionRate();
        require(msg.value.getConversionRate(s_priceFeed) >= minUsd, "Didnt send enough Ethers"); //1e18 = 1ETH = 10^18 WEI
        s_addressToAmountFunded[msg.sender]  +=  msg.value;
        s_funders.push(msg.sender);
        
    }


    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner{ //It takes lest amount of gas as compare to the Older Withdraw() function
    // It takes 800-1000 less wei gas 
    uint256 funderLength = s_funders.length;
    for(uint256 funderIndex=0; funderIndex<funderLength; funderIndex++){
        address funder = s_funders[funderIndex];
        s_addressToAmountFunded[funder] = 0;
    }
    s_funders= new address[](0);
    payable(msg.sender).transfer(address(this).balance);

        //Send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Payment Failed"); //if tranx failed, this mssg will showup

        //Call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Call Failed");


    }

    function withdraw() public onlyOwner {
        // we use here for loop
        //for(starting index, ending index, step amount)
        for(uint256 funderIndex=0; funderIndex<s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;

        }
        // reset the funders array
        s_funders= new address[](0);
        //actually withdraw the funds
        
        // transfer -> send -> call

        //Transfer
        // msg.sender = address
        //payable(msg.sender = payable address
        payable(msg.sender).transfer(address(this).balance);

        //Send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Payment Failed"); //if tranx failed, this mssg will showup

        //Call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Call Failed");
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Must be owner!!"); //it using the contructor 
        _;     // this means 'you can add anything in function after this'
    }

    receive() external payable{
        fund();
    }
    
    fallback() external payable{
        fund();
    }

    function getAddresstoAmountFunded(address fundingAddress) external view returns (uint256){
    
        return s_addressToAmountFunded[fundingAddress];
        
    }

    function getFunders(uint256 index) external view returns (address){
        return s_funders[index];
    }

    function getOwner() external view returns (address){
        return owner;
    }


}