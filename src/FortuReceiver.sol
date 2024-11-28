// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import {IOAppComposer} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import "./interfaces/IFortupool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title FortuReceiver Contract
/// @dev This contract will call FortuPool to buy the tiket.
/// @notice The contract is designed to interact with LayerZero's Omnichain Fungible Token (OFT) Standard,
/// allowing it to respond to cross-chain OFT mint events with a token swap action.
contract FortuReceiver is IOAppComposer, Ownable {
    using SafeERC20 for IERC20;
    /**
     * @notice The ERC20 token that will be used to buy tickets.
     */

    IERC20 public usde;
    /**
     * @notice The LayerZero Endpoint address.
     */
    address public immutable endpoint;
    /**
     * @notice The address of the OApp that is sending the composed message.
     */
    address public oApp;
    /**
     * @notice The address of the FortuPool contract.
     */
    address public fortuPool;

    error FORTA_RECEIVER__INVALID_OAPP_ADDRESS(address oApp);
    error FORTA_RECEIVER__NOT_ALLOWED();

    /// @notice Constructs the SwapMock contract.
    /// @dev Initializes the contract.
    /// @param _erc20 The address of the ERC20 token that will be used in swaps.
    /// @param _endpoint LayerZero Endpoint address
    /// @param _oApp The address of the OApp that is sending the composed message.
    constructor(address _erc20, address _endpoint, address _oApp, address _fortu) Ownable(msg.sender) {
        usde = IERC20(_erc20);
        endpoint = _endpoint;
        oApp = _oApp;
        fortuPool = _fortu;
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload to perform a token swap.
    ///      This method expects the encoded compose message to contain the swap amount and recipient address.
    /// @param _oApp The address of the originating OApp.
    /// @param /*_guid*/ The globally unique identifier of the message (unused in this mock).
    /// @param _message The encoded message content in the format of the OFTComposeMsgCodec.
    /// @param /*Executor*/ Executor address (unused in this mock).
    /// @param /*Executor Data*/ Additional data for checking for a specific executor (unused in this mock).
    function lzCompose(
        address _oApp,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*Executor*/
        bytes calldata /*Executor Data*/
    ) external payable override {
        if (_oApp != oApp) revert FORTA_RECEIVER__INVALID_OAPP_ADDRESS(_oApp);
        if (msg.sender != endpoint) revert FORTA_RECEIVER__NOT_ALLOWED();

        (address _buyer, uint256 _amount) = abi.decode(OFTComposeMsgCodec.composeMsg(_message), (address, uint256));

        usde.safeTransfer(fortuPool, _amount);
        IFortupool(fortuPool).buyFromLZ(_buyer, _amount);
    }
    /**
     * @notice Sets the address of the FortuPool contract.
     * @param _fortu The address of the FortuPool contract.
     */
    function setFortuPool(address _fortu) external onlyOwner {
        fortuPool = _fortu;
    }
<<<<<<< Updated upstream

    function setUSDE(address _usde) external onlyOwner {
        usde = IERC20(_usde);
    }

    function setOAPP(address _oApp) external onlyOwner {
        oApp = _oApp;
    }
}
=======
    /**
     * @notice Sets the address of the ERC20 token that will be used to buy tickets.
     * @param _usde The address of the ERC20 token that will be used to buy tickets.
     */
    function setUSDE(address _usde) external onlyOwner {
        usde = IERC20(_usde);
    }
    /**
     * @notice Sets the address of the OApp that is sending the composed message.
     * @param _oApp The address of the OApp that is sending the composed message.
     */
    function setOAPP(address _oApp) external onlyOwner {
        oApp = _oApp;
    }
    /**
     * @notice Composes the message to be sent to the FortuPool contract.
     * @param _buyer The address of the buyer.
     * @param _amount The amount of tokens to be sent.
     * @return The encoded message content.
     */
    function composeMessage(address _buyer, uint256 _amount) external view returns (bytes memory) {
        return abi.encode(_buyer, _amount);
    }
}
>>>>>>> Stashed changes
