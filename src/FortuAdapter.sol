pragma solidity ^0.8.22;

import { OFTAdapter } from "LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFortupool.sol";

/// @notice OFTAdapter uses a deployed ERC-20 token and safeERC20 to interact with the OFTCore contract.
contract USDEAdapter is OFTAdapter {

    address public fortuPool;

    constructor(
        address _token,
        address _lzEndpoint,
        address _owner
    ) OFTAdapter(_token, _lzEndpoint, _owner) Ownable(_owner) {}

    function setFortuPool(address _fortuPool) external onlyOwner {
        fortuPool = _fortuPool;
    }

    function lzCompose(address _from, address _to, bytes32 _guid, uint16 _index, bytes _message, bytes _extraData) external payable {
        (buyer, amount) = abi.decode(_message, (address, uint256));
        IERC20(token).approve(fortuPool, amount);
        IFortupool(fortuPool).buyFromLZ(buyer, amount);
    }

}