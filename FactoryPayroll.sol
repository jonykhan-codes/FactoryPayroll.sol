// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FactoryPayroll
 * @dev Smart contract for managing factory worker payments on Arc Testnet
 */
contract FactoryPayroll {
    address public owner;

    struct Worker {
        string name;
        uint256 dailyRate;
        bool isActive;
        uint256 lastPaidTime;
    }

    mapping(address => Worker) public workers;
    address[] public workerAddresses;

    event WorkerAdded(address indexed workerAddress, string name, uint256 dailyRate);
    event WorkerPaid(address indexed workerAddress, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only factory owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 1. Register a new worker
    function addWorker(address _workerAddress, string memory _name, uint256 _dailyRate) external onlyOwner {
        require(!workers[_workerAddress].isActive, "Worker already exists");
        
        workers[_workerAddress] = Worker({
            name: _name,
            dailyRate: _dailyRate,
            isActive: true,
            lastPaidTime: block.timestamp
        });

        workerAddresses.push(_workerAddress);
        emit WorkerAdded(_workerAddress, _name, _dailyRate);
    }

    // 2. Deposit funds into contract
    receive() external payable {}

    // 3. Execute batch payout to all active workers
    function payAllWorkers() external onlyOwner {
        for (uint256 i = 0; i < workerAddresses.length; i++) {
            address workerAddr = workerAddresses[i];
            Worker storage worker = workers[workerAddr];

            if (worker.isActive) {
                uint256 payAmount = worker.dailyRate;
                require(address(this).balance >= payAmount, "Insufficient contract balance");

                worker.lastPaidTime = block.timestamp;
                
                (bool success, ) = payable(workerAddr).call{value: payAmount}("");
                require(success, "Transfer failed");

                emit WorkerPaid(workerAddr, payAmount);
            }
        }
    }

    // 4. Get total contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
