// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import "./interfaces/ISUSDE.sol";

contract Fortupool is Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface private immutable CoordinatorInterface;
    uint64 private immutable _subscriptionId;
    address private immutable _vrfCoordinatorV2Address;
    bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    struct Ticket {
        uint256 blockNumber;
        uint256 amount;
    }

    struct RandomNum {
        uint256 requestId;
        uint256 batchLuckyNumber;
    }

    uint256 public TOTAL_STACKED_BATCH;
    uint256 public TOTAL_STACKED;
    uint256 public CURRENT_BATCH;
    uint256 public TICKET_PRICE;

    uint256 public currentBatch;

    IERC20 internal usdeContract;
    ISUSDE internal susdeContract;

    bool public batchPausePeriod;

    address[] public operatorAddress;

    mapping(uint256 => mapping(address => Ticket)) public batchPools;
    mapping(uint256 => RandomNum) public batchLuckyNumber;
    mapping(uint256 => uint256) public batchTotalStacked;

    event JoinRaffle(address wallet, uint256 amount, uint256 batch, uint256 timestamp);
    event Withdraw(address wallet, uint256 amount, uint256 batch, uint256 timestamp);
    event BatchLuckyNumber(uint256 batch, uint256 luckyNumber, uint256 timestamp);
    event GenerateRandom(uint256 requestId, uint256 batch, uint256 timestamp);

    error FORTU__ZERO_AMOUNT();
    error FORTU__WALLET_NOT_ALLOWED(address wallet);
    error FORTU__ON_PUASE_PERIOD();
    error FORTU__BATCH_STILL_ONGOING();
    error FORTU__INVALID_AMOUNT();
    error FORTU__ALLOWANCE_NOT_ENOUGH();
    error FORTU__UNIFFICIENT_BALANCE();

    constructor(
        address _susde,
        address _usde,
        address _operator,
        address vrfCoordinatorV2Address,
        uint64 subscriptionId
    ) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorV2Address) {
        currentBatch = 1;
        usdeContract = IERC20(_usde);
        susdeContract = ISUSDE(_susde);
        batchPausePeriod = false;
        operatorAddress.push(_operator);
        _subscriptionId = subscriptionId;
        _vrfCoordinatorV2Address = vrfCoordinatorV2Address;
        CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
    }

    function addOpertaor(address _operator) external onlyOwner {
        operatorAddress.push(_operator);
    }

    function rejoinBacth() external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount == 0) revert FORTU__ZERO_AMOUNT();

        emit JoinRaffle(msg.sender, batchPools[currentBatch][msg.sender].amount, currentBatch, block.timestamp);
    }

    function buyTicket(uint256 _amount) external {
        if (_amount == 0) revert FORTU__ZERO_AMOUNT();
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (TICKET_PRICE % _amount != 0) revert FORTU__INVALID_AMOUNT();
        if (usdeContract.balanceOf(msg.sender) < _amount) revert FORTU__UNIFFICIENT_BALANCE();
        if (usdeContract.allowance(msg.sender, address(this)) < _amount) revert FORTU__ALLOWANCE_NOT_ENOUGH();

        usdeContract.transferFrom(msg.sender, address(this), _amount);
        batchPools[currentBatch][msg.sender].blockNumber = block.number;
        batchPools[currentBatch][msg.sender].amount += _amount;

        batchTotalStacked[currentBatch] += _amount;

        emit JoinRaffle(msg.sender, _amount, currentBatch, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount < _amount) revert FORTU__UNIFFICIENT_BALANCE();

        uint256 _susdeAmount = susdeContract.convertToShares(_amount);
        susdeContract.transfer(msg.sender, _susdeAmount);
        batchPools[currentBatch][msg.sender].amount -= _amount;
        batchPools[currentBatch][msg.sender].blockNumber = block.number;

        batchTotalStacked[currentBatch] -= _amount;

        emit Withdraw(msg.sender, _amount, currentBatch, block.timestamp);
    }

    function generateRandom() external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        uint256 reqId = CoordinatorInterface.requestRandomWords(
            keyHash, _subscriptionId, blockConfirmations, callbackGasLimit, numWords
        );

        emit GenerateRandom(reqId, currentBatch, block.timestamp);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 luckyNumber = (randomWords[0] % batchTotalStacked[currentBatch]) + 1;
        batchLuckyNumber[currentBatch].batchLuckyNumber = luckyNumber;
        batchLuckyNumber[currentBatch].requestId = requestId;

        emit BatchLuckyNumber(currentBatch, luckyNumber, block.timestamp);
    }

    function distributePrize() external {
        if (!batchPausePeriod) revert FORTU__BATCH_STILL_ONGOING();
        // function to distribute prize
    }

    function generateLuckyNumber() external {
        // function to generate lucky number using chainlink VRF
        // soon
    }
}
