pragma solidity ^0.8.22;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice OFTAdapter uses a deployed ERC-20 token and safeERC20 to interact with the OFTCore contract.
contract FortuAdapter is OFTAdapter {
    /**
     * @notice Constructs the OFTAdapter contract.
     * @param _token The address of the ERC-20 token.
     * @param _lzEndpoint The address of the LayerZero endpoint.
     * @param _owner The address of the owner.
     */
    constructor(address _token, address _lzEndpoint, address _owner)
        OFTAdapter(_token, _lzEndpoint, _owner)
        Ownable(_owner)
    {}
}
