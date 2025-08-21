// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {AyaMarket} from "../src/AyaMarket.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AyaMarketTest is Test {
    AyaMarket market;
    address stablecoin = address(0x123);
    
    // Test accounts
    address seller = address(1);
    address buyer = address(2);

    function setUp() public {
        market = new AyaMarket(stablecoin);
    }
}