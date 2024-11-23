// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { OptionsBuilder } from 'LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol';

import {Test, console} from "forge-std/Test.sol";
contract LZTest {
    using OptionsBuilder for bytes;
    function setUp(){}

    function test_increment() public view {
        bytes memory options = OptionsBuilder.newOptions();
        bytes memory updatedOptions = options.addExecutorLzReceiveOption(1500000, 0);
        console.log(updatedOptions);
    }
}