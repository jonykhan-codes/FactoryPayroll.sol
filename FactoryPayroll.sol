// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FactoryPayroll {
    address public owner;

    struct Worker {
        string name;
        uint256 dailyRate; // Value in Wei / 6-decimal units
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

    // কন্ট্রাক্টে সরাসরি USDC ডিপোজিট নেওয়ার জন্য
    receive() external payable {}

    function payAllWorkers() external onlyOwner {
        for (uint256 i = 0; i < workerAddresses.length; i++) {
            address workerAddr = workerAddresses[i];
            Worker storage worker = workers[workerAddr];

            if (worker.isActive) {
                uint256 payAmount = worker.dailyRate;
                require(address(this).balance >= payAmount, "Insufficient USDC balance in contract");

                worker.lastPaidTime = block.timestamp;
                
                (bool success, ) = payable(workerAddr).call{value: payAmount}("");
                require(success, "USDC Payment transfer failed");

                emit WorkerPaid(workerAddr, payAmount);
            }
        }
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
