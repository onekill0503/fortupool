// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Fortupool.sol";
import "../src/interfaces/ISUSDE.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FortupoolTest is Test {
    Fortupool public fortu;
    ERC20 public usde;
    ISUSDE public susde;
    address usdeAddress = 0x0D696D24f0C061102110Bdb8c54A27209806eBC0;
    address susdeAddress = 0x165C8426a5922e4450159146e3deaa0C15A69c17;
    address payable fortuSC = payable(address(0x99A1733F51097309E4eDEe97A65f3bB0aa42754d));

    address public userX = 0xeb14327D7aD929466cD078421A169E90f729FEE2;

    function setUp() public {
        // vm.createSelectFork("https://sepolia.infura.io/v3/7d1dde020bdf4d69af5b4cdf0e3d7578", 7121913);
        usde = ERC20(usdeAddress);
        susde = ISUSDE(susdeAddress);

        // donate = new Donate(platform, susdeAddress, usdeAddress);
        fortu = Fortupool(fortuSC);
    }

    function test_BuyTicket() public {

        vm.startPrank(userX);
        usde.approve(address(fortu), 100 ether);

        fortu.buyTicket(100 ether);
        vm.stopPrank();
    }
}
