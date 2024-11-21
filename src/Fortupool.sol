// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "./interfaces/ISUSDE.sol";

contract Fortupool is Ownable, VRFV2PlusWrapperConsumerBase {
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    struct Ticket {
        uint256 blockNumber;
        uint256 amount;
    }

    struct RandomNum {
        uint256 requestId;
        uint256 randomNums;
    }

    struct FinalWinner {
        uint256 batch;
        address winner;
        uint256 luckyNumber;
    }

    struct OperatorSubmit {
        uint256 batch;
        address winner;
        uint256 luckyNumber;
    }

    uint256 public TOTAL_STACKED_BATCH;
    uint256 public TOTAL_STACKED;
    uint256 public CURRENT_BATCH;
    uint256 public TICKET_PRICE;
    uint256 public PLATFORM_PERCENTAGE = 10;
    uint256 public TOTAL_FEES_COLLECTED;
    uint256 public MIN_OPERATOR_CONFIRM = 2;
    uint256 public BLOCK_TO_TICKET_RATIO = 1000;

    uint256 public currentBatch;

    IERC20 internal usdeContract;
    ISUSDE internal susdeContract;

    // sepolia chainlink vrf
    address public linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public wrapperAddress = 0x195f15F2d49d693cE265b4fB0fdDbE15b1850Cc1;

    bool public batchPausePeriod;

    address[] public operatorAddress;

    mapping(uint256 => mapping(address => Ticket)) public batchPools;
    mapping(uint256 => RandomNum) public randomNumbers;
    mapping(uint256 => uint256) public batchTotalStacked;
    mapping(uint256 => FinalWinner) public finalWinners;
    mapping(uint256 => mapping(address => bool)) public operatorConfirm;
    mapping(uint256 => OperatorSubmit[]) public operatorSubmit;

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

    constructor(address _susde, address _usde, uint256 _price) Ownable(msg.sender) VRFV2PlusWrapperConsumerBase(wrapperAddress) {
        currentBatch = 0;
        usdeContract = IERC20(_usde);
        susdeContract = ISUSDE(_susde);
        batchPausePeriod = false;
        TICKET_PRICE = _price;
    }

    function addOpertaor(address _operator) external onlyOwner {
        operatorAddress.push(_operator);
    }

    function updateTicketPrice(uint256 _price) external onlyOwner {
        if (_price == 0) revert FORTU__ZERO_AMOUNT();
        TICKET_PRICE = _price;
    }

    function rejoinBacth() external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount == 0) revert FORTU__ZERO_AMOUNT();

        emit JoinRaffle(msg.sender, batchPools[currentBatch][msg.sender].amount, currentBatch, block.number, block.timestamp);
    }

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

        emit JoinRaffle(msg.sender, _amount, currentBatch, block.number, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount < _amount) revert FORTU__UNIFFICIENT_BALANCE();

        uint256 _susdeAmount = susdeContract.convertToShares(_amount);
        susdeContract.transfer(msg.sender, _susdeAmount);
        batchPools[currentBatch][msg.sender].amount -= _amount;
        batchPools[currentBatch][msg.sender].blockNumber = block.number;

        batchTotalStacked[currentBatch] -= _amount;

        emit Withdraw(msg.sender, _amount, currentBatch, block.number, block.timestamp);
    }

    function generateLuckyNumber() external {
        if (isValidOperator(msg.sender)) revert FORTU__WALLET_NOT_ALLOWED(msg.sender);

        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}));
        uint256 requestId;
        uint256 reqPrice;

        (requestId, reqPrice) = requestRandomnessPayInNative(callbackGasLimit, blockConfirmations, numWords, extraArgs);

        randomNumbers[currentBatch].requestId = requestId;

        emit GenerateRandom(requestId, currentBatch, block.number, block.timestamp);
        batchPausePeriod = true;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        randomNumbers[currentBatch].randomNums = _randomWords[0];
        randomNumbers[currentBatch].requestId = _requestId;

        emit BatchLuckyNumber(currentBatch, _randomWords[0], block.number, block.timestamp);
    }

    function pickWinner() external onlyOwner {
        if (!batchPausePeriod) revert FORTU__BATCH_IS_ONGOING();
        uint256 totalConfirmed = 1;

        for (uint256 i = 0; i < operatorSubmit[currentBatch].length - 2; i++) {
            if (operatorSubmit[currentBatch][i].luckyNumber == operatorSubmit[currentBatch][i + 1].luckyNumber) {
                totalConfirmed++;
            }
        }
        if (totalConfirmed < MIN_OPERATOR_CONFIRM) revert FORTU__NOT_ENOUGH_OPERATOR_CONFIRM();

        finalWinners[currentBatch] = FinalWinner(
            currentBatch, operatorSubmit[currentBatch][0].winner, operatorSubmit[currentBatch][0].luckyNumber
        );
    }

    function submitWinner(uint256 luckyNumber, address winner) external {
        if (isValidOperator(msg.sender)) revert FORTU__WALLET_NOT_ALLOWED(msg.sender);
        if (!batchPausePeriod) revert FORTU__BATCH_IS_ONGOING();
        if (operatorConfirm[currentBatch][msg.sender]) {
            revert FORTU__OPERATOR_ALREADY_SUBMIT(msg.sender, block.timestamp);
        }

        operatorSubmit[currentBatch].push(OperatorSubmit(currentBatch, winner, luckyNumber));
        operatorConfirm[currentBatch][msg.sender] = true;
    }

    function distributePrize() external onlyOwner {
        if (batchPausePeriod) revert FORTU__BATCH_IS_ONGOING();
        if (finalWinners[currentBatch].winner == address(0)) revert FORTU__WINNER_NOT_PICKED();

        uint256 totalUsdeCurrentBatch = batchTotalStacked[currentBatch];
        uint256 totalsUSDe = usdeContract.balanceOf(address(this));
        uint256 totalYieldCurrentBatch = susdeContract.previewRedeem(totalsUSDe) - totalUsdeCurrentBatch;
        uint256 distributedsUSDe = susdeContract.convertToShares(totalYieldCurrentBatch);
        uint256 platformFees = (distributedsUSDe * PLATFORM_PERCENTAGE) / 100e18;

        susdeContract.transfer(finalWinners[currentBatch].winner, (distributedsUSDe - platformFees));
        TOTAL_FEES_COLLECTED += platformFees;
        currentBatch += 1;
        batchPausePeriod = false;
    }

    function isValidOperator(address _operator) internal view returns (bool) {
        for (uint256 i = 0; i < operatorAddress.length; i++) {
            if (operatorAddress[i] == _operator) {
                return true;
            }
        }
        return false;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function withdrawFees() external onlyOwner {
        susdeContract.transfer(owner(), TOTAL_FEES_COLLECTED);
        TOTAL_FEES_COLLECTED = 0;
    }

    function withdrawNative(uint256 amount) external onlyOwner {
        (bool success,) = payable(owner()).call{value: amount}("");
        // solhint-disable-next-line gas-custom-errors
        require(success, "withdrawNative failed");
    }

    receive() external payable {}
}
