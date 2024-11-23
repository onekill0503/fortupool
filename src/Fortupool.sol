// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "./interfaces/ISUSDE.sol";

contract FortuPool is Ownable, VRFV2PlusWrapperConsumerBase {
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    /**
     * @notice The Ticket struct represents a ticket in the pool for specific user
     */
    struct Ticket {
        uint256 blockNumber;
        uint256 amount;
    }
    /**
     * @notice The RandomNum struct represents a random number for specific batch
     */
    struct RandomNum {
        uint256 requestId;
        uint256 randomNums;
    }
    /**
     * @notice The FinalWinner struct represents the final winner for specific batch
     */
    struct FinalWinner {
        uint256 batch;
        address winner;
        uint256 luckyNumber;
    }

    /**
     * @notice The TOTAL_STACKED represents the total amount of USDe stacked in the pool
     */
    uint256 public TOTAL_STACKED;
    /**
     * @notice The TICKET_PRICE represents the price of the ticket
     */
    uint256 public TICKET_PRICE;
    /**
     * @notice The PLATFORM_PERCENTAGE represents the percentage of the platform fees
     */
    uint256 public PLATFORM_PERCENTAGE = 10;
    /**
     * @notice The TOTAL_FEES_COLLECTED represents the total amount of fees collected
     */
    uint256 public TOTAL_FEES_COLLECTED;
    /**
     * @notice The BLOCK_TO_TICKET_RATIO represents the ratio of the block to the ticket
     */
    uint256 public BLOCK_TO_TICKET_RATIO = 1000;
    /**
     * @notice The FORTU_RECEIVER represents the address of the LZAdapter contract
     */
    uint256 public FORTU_RECEIVER = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    /**
     * @notice The currentBatch represents the current/active batch number
     */
    uint256 public currentBatch;
    /**
     * @notice The usdeContract represents the address of the USDe contract
     */
    IERC20 internal usdeContract;
    /**
     * @notice The susdeContract represents the address of the SUSDe contract
     */
    ISUSDE internal susdeContract;
    /**
     * @notice The linkAddress represents the address of the LINK token (static at base sepolia)
     */
    address public linkAddress = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    /**
     * @notice The wrapperAddress represents the address of the VRFV2PlusWrapper contract (static at base sepolia)
     */
    address public wrapperAddress = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    /**
     * @notice The batchPausePeriod represents the status of the batch pause period
     */
    bool public batchPausePeriod;
    /**
     * @notice The operatorAddress represents the list of operators
     */
    address[] public operatorAddress;
    /**
     * @notice The batchPools represents the mapping of the batch pools per batch
     */
    mapping(uint256 => mapping(address => Ticket)) public batchPools;
    /**
     * @notice The randomNumbers represents the mapping of the random numbers per batch
     */
    mapping(uint256 => RandomNum) public randomNumbers;
    /**
     * @notice The batchTotalStacked represents the mapping of the total stacked per batch
     */
    mapping(uint256 => uint256) public batchTotalStacked;
    /**
     * @notice The finalWinners represents the mapping of the final winners per batch
     */
    mapping(uint256 => FinalWinner) public finalWinners;
    /**
     * @notice The operatorConfirm represents the mapping of the operator confirmations per batch
     */
    mapping(uint256 => mapping(address => bool)) public operatorConfirm;
    
    event JoinRaffle(address wallet, uint256 amount, uint256 batch, uint256 block, uint256 timestamp);
    event Withdraw(address wallet, uint256 amount, uint256 batch, uint256 block, uint256 timestamp);
    event BatchLuckyNumber(uint256 batch, uint256 luckyNumber, uint256 block, uint256 timestamp);
    event GenerateRandom(uint256 requestId, uint256 batch, uint256 block, uint256 timestamp);

    error FORTU__ZERO_AMOUNT();
    error FORTU__WALLET_NOT_ALLOWED(address wallet);
    error FORTU__ON_PUASE_PERIOD();
    error FORTU__INVALID_AMOUNT();
    error FORTU__ALLOWANCE_NOT_ENOUGH();
    error FORTU__UNIFFICIENT_BALANCE();
    error FORTU__OPERATOR_ALREADY_SUBMIT(address operator, uint256 timestamp);
    error FORTU__NOT_ENOUGH_OPERATOR_CONFIRM();
    error FORTU__BATCH_IS_ONGOING();
    error FORTU__WINNER_NOT_PICKED();
    error FORTU__PRIZE_ZERO();

    /**
     * @notice Constructs the FortuPool contract.
     * @param _susde The address of the SUSDe contract.
     * @param _usde The address of the USDe contract.
     */
    constructor(address _susde, address _usde) Ownable(msg.sender) VRFV2PlusWrapperConsumerBase(wrapperAddress) {
        currentBatch = 0;
        usdeContract = IERC20(_usde);
        susdeContract = ISUSDE(_susde);
        batchPausePeriod = false;
    }
    /**
     * @notice Adds an operator to the operatorAddress list.
     * @param _operator The address of the operator.
     */
    function addOpertaor(address _operator) external onlyOwner {
        operatorAddress.push(_operator);
    }
    /**
     * @notice Removes an operator from the operatorAddress list.
     * @param _operator The address of the operator.
     */
    function removeOperator(address _operator) external onlyOwner {
        for (uint256 i = 0; i < operatorAddress.length; i++) {
            if (operatorAddress[i] == _operator) {
                delete operatorAddress[i];
            }
        }
    }
    /**
     * @notice updates the ticket price
     * @param _price The price of the ticket.
     */
    function updateTicketPrice(uint256 _price) external onlyOwner {
        if (_price == 0) revert FORTU__ZERO_AMOUNT();
        TICKET_PRICE = _price;
    }
    /**
     * @notice updates the ratio block to ticket
     * @param _ratio The ratio of the block to the ticket.
     */
    function updateBlockToTicketRatio(uint256 _ratio) external onlyOwner {
        if (_ratio == 0) revert FORTU__ZERO_AMOUNT();
        BLOCK_TO_TICKET_RATIO = _ratio;
    }
    /**
     * @notice update the address of Fortu contract receiver
     * @param _receiver The address of the fortu contract receiver.
     */
    function setFortuReceiver(address _receiver) external onlyOwner {
        FORTU_RECEIVER = _adapter;
    }
    /**
     * @notice function to user rejoin the batch if last batch was finish and user need to rejoin it
     */
    function rejoinBacth() external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount == 0) revert FORTU__ZERO_AMOUNT();

        emit JoinRaffle(
            msg.sender, batchPools[currentBatch][msg.sender].amount, currentBatch, block.number, block.timestamp
        );
    }
    /**
     * @notice function to user buy ticket from LZAdapter contract
     * @param _buyer The address of the buyer.
     * @param _amount The amount of usde.
     */
    function buyFromLZ(address _buyer, uint256 _amount) external {
        if (msg.sender != FORTU_RECEIVER) revert FORTU__WALLET_NOT_ALLOWED(msg.sender);
        if (_amount == 0) revert FORTU__ZERO_AMOUNT();

        uint256 refundUSDe = _amount % TICKET_PRICE;
        if (refundUSDe != 0) {
            usdeContract.transfer(_buyer, refundUSDe);
        }
        uint256 netAmount = (_amount - refundUSDe);
        usdeContract.approve(address(susdeContract), netAmount);
        susdeContract.deposit(netAmount, address(this));

        batchPools[currentBatch][_buyer].blockNumber = block.number;
        batchPools[currentBatch][_buyer].amount += _amount;

        batchTotalStacked[currentBatch] += _amount;

        TOTAL_STACKED += _amount;

        emit JoinRaffle(_buyer, _amount, currentBatch, block.number, block.timestamp);
    }
    /**
     * @notice function to user buy ticket
     * @param _amount The amount of usde to buy ticket.
     */
    function buyTicket(uint256 _amount) external {
        if (_amount == 0) revert FORTU__ZERO_AMOUNT();
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (_amount % TICKET_PRICE != 0) revert FORTU__INVALID_AMOUNT();
        if (usdeContract.balanceOf(msg.sender) < _amount) revert FORTU__UNIFFICIENT_BALANCE();
        if (usdeContract.allowance(msg.sender, address(this)) < _amount) revert FORTU__ALLOWANCE_NOT_ENOUGH();

        usdeContract.transferFrom(msg.sender, address(this), _amount);
        usdeContract.approve(address(susdeContract), _amount);
        susdeContract.deposit(_amount, address(this));

        batchPools[currentBatch][msg.sender].blockNumber = block.number;
        batchPools[currentBatch][msg.sender].amount += _amount;

        batchTotalStacked[currentBatch] += _amount;

        TOTAL_STACKED += _amount;

        emit JoinRaffle(msg.sender, _amount, currentBatch, block.number, block.timestamp);
    }
    /**
     * @notice function to user withdraw ticket
     * @param _amount The amount of usde to withdraw.
     */
    function withdraw(uint256 _amount) external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount < _amount) revert FORTU__UNIFFICIENT_BALANCE();

        uint256 _susdeAmount = susdeContract.convertToShares(_amount);
        susdeContract.transfer(msg.sender, _susdeAmount);
        batchPools[currentBatch][msg.sender].amount -= _amount;
        batchPools[currentBatch][msg.sender].blockNumber = block.number;

        batchTotalStacked[currentBatch] -= _amount;

        TOTAL_STACKED -= _amount;

        emit Withdraw(msg.sender, _amount, currentBatch, block.number, block.timestamp);
    }
    /**
     * @notice function to owner generate lucky number for current batch using chainlink VRF
     */
    function generateLuckyNumber() external onlyOwner {

        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}));
        uint256 requestId;
        uint256 reqPrice;

        (requestId, reqPrice) = requestRandomnessPayInNative(callbackGasLimit, blockConfirmations, numWords, extraArgs);

        randomNumbers[currentBatch].requestId = requestId;

        emit GenerateRandom(requestId, currentBatch, block.number, block.timestamp);
        batchPausePeriod = true;
    }
    /**
     * @notice function to catch chainlink callback and fulfill the random number
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        randomNumbers[currentBatch].randomNums = _randomWords[0];
        randomNumbers[currentBatch].requestId = _requestId;

        emit BatchLuckyNumber(currentBatch, _randomWords[0], block.number, block.timestamp);
    }
    /**
     * @notice function to operator submit the winner
     * @param luckyNumber The lucky number.
     * @param winner The address of the winner.
     */
    function submitWinner(uint256 luckyNumber, address winner) external {
        if (!isValidOperator(msg.sender)) revert FORTU__WALLET_NOT_ALLOWED(msg.sender);
        if (!batchPausePeriod) revert FORTU__BATCH_IS_ONGOING();
        if (operatorConfirm[currentBatch][msg.sender]) {
            revert FORTU__OPERATOR_ALREADY_SUBMIT(msg.sender, block.timestamp);
        }

        finalWinners[currentBatch] = FinalWinner(currentBatch, winner, luckyNumber);

        distributePrize(winner);
    }
    /**
     * @notice function to distribute current batch prize to the winner
     */
    function distributePrize(address winner) internal {
        uint256 totalUsdeCurrentBatch = batchTotalStacked[currentBatch];
        uint256 totalsUSDe = susdeContract.balanceOf(address(this));
        uint256 redeem = susdeContract.previewRedeem(totalsUSDe);
        uint256 totalYieldCurrentBatch = 0;
        if (redeem > totalUsdeCurrentBatch) {
            totalYieldCurrentBatch = redeem - totalUsdeCurrentBatch;
        }
        if (totalYieldCurrentBatch == 0) revert FORTU__PRIZE_ZERO();
        uint256 distributedsUSDe = susdeContract.convertToShares(totalYieldCurrentBatch);
        uint256 platformFees = (distributedsUSDe * PLATFORM_PERCENTAGE) / 100e18;

        susdeContract.transfer(winner, (distributedsUSDe - platformFees));
        TOTAL_FEES_COLLECTED += platformFees;
        currentBatch += 1;
        batchPausePeriod = false;
    }
    /**
     * @notice function to check if the operator is valid
     * @param _operator The address of the operator.
     */
    function isValidOperator(address _operator) public view returns (bool) {
        for (uint256 i = 0; i < operatorAddress.length; i++) {
            if (operatorAddress[i] == _operator) {
                return true;
            }
        }
        return false;
    }
    /**
     * @notice function to withdraw link token from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    /**
     * @notice function to withdraw platform fees from the contract
     */
    function withdrawFees() external onlyOwner {
        susdeContract.transfer(owner(), TOTAL_FEES_COLLECTED);
        TOTAL_FEES_COLLECTED = 0;
    }
    /**
     * @notice function to withdraw native token from the contract
     * @param amount The amount of native token.
     */
    function withdrawNative(uint256 amount) external onlyOwner {
        (bool success,) = payable(owner()).call{value: amount}("");
        // solhint-disable-next-line gas-custom-errors
        require(success, "withdrawNative failed");
    }

    receive() external payable {}
}
