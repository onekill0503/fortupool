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
    address usdeAddress = 0x9e06Ac052e5929744485F2D350A9b98e2F74e1A4;
    address susdeAddress = 0x51fFD3785c15cb59a7287b7C18cb16C0F1d2915b;

    address public owner = 0x36892087eF1242D6393Da18B9127CfD546f86E6F;
    address public userX = 0xeb14327D7aD929466cD078421A169E90f729FEE2;
    address public userY = 0x77D7703056602B548CaE408aC33e7775A22D9eDe;
    address public operator = 0xF63fb6da9b0EEdD4786C8ee464962b5E1b17AD1d;

    function setUp() public {
        vm.createSelectFork("https://sepolia.base.org", 18229557);
        vm.startPrank(owner);
        usde = ERC20(usdeAddress);
        susde = ISUSDE(susdeAddress);

        fortu = new Fortupool(susdeAddress, usdeAddress);
        vm.stopPrank();
        // fortu = Fortupool(fortuSC);
    }

    function test_BuyTicket() public {
        // Setup Fortu Contract
        vm.startPrank(owner);
        assertEq(fortu.owner(), address(owner));
        fortu.addOpertaor(operator);
        assertEq(fortu.isValidOperator(operator), true);
        fortu.updateTicketPrice(1 ether);
        assertEq(fortu.TICKET_PRICE(), 1 ether);
        vm.stopPrank();

        vm.startPrank(userX);
        usde.approve(address(fortu), 100 ether);
        assertEq(usde.allowance(userX, address(fortu)), 100 ether);
        fortu.buyTicket(100 ether);
        vm.stopPrank();
        vm.startPrank(userY);
        usde.approve(address(fortu), 100 ether);
        assertEq(usde.allowance(userY, address(fortu)), 100 ether);
        fortu.buyTicket(100 ether);
        vm.stopPrank();
    }
}
