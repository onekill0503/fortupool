// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISUSDE.sol";

contract Fortupool is Ownable {
    struct Ticket {
        uint256 blockNumber;
        uint256 amount;
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

    event JoinRaffle(address wallet, uint256 amount, uint256 batch, uint256 timestamp);
    event Withdraw(address wallet, uint256 amount, uint256 batch, uint256 timestamp);

    error FORTU__ZERO_AMOUNT();
    error FORTU__WALLET_NOT_ALLOWED(address wallet);
    error FORTU__ON_PUASE_PERIOD();
    error FORTU__BATCH_STILL_ONGOING();
    error FORTU__INVALID_AMOUNT();
    error FORTU__ALLOWANCE_NOT_ENOUGH();
    error FORTU__UNIFFICIENT_BALANCE();

    constructor(address _susde, address _usde, address _operator) Ownable(msg.sender) {
        currentBatch = 1;
        usdeContract = IERC20(_usde);
        susdeContract = ISUSDE(_susde);
        batchPausePeriod = false;
        operatorAddress.push(_operator);
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

        emit JoinRaffle(msg.sender, _amount, currentBatch, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        if (batchPausePeriod) revert FORTU__ON_PUASE_PERIOD();
        if (batchPools[currentBatch][msg.sender].amount < _amount) revert FORTU__UNIFFICIENT_BALANCE();

        uint256 _susdeAmount = susdeContract.convertToShares(_amount);
        susdeContract.transfer(msg.sender, _susdeAmount);
        batchPools[currentBatch][msg.sender].amount -= _amount;
        batchPools[currentBatch][msg.sender].blockNumber = block.number;

        emit Withdraw(msg.sender, _amount, currentBatch, block.timestamp);
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
