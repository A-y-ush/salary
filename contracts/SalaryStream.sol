// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title On-Demand Salary Disbursement Contract
/// @author Your Name/Organization
/// @notice This contract manages on-demand salary payments to employees.

contract OnDemandSalary {
    // State Variables
    address public immutable manager; 
    mapping(address => uint256) public employeeSalaryCycleStart;
    mapping(address => uint256) public employeeBalance; 
    mapping(address => bool) public isStreaming;  
    mapping(address => uint256)public salariesPerSecond;
    uint256 public constant SALARY_PER_SECOND = 100; 

    // Events
    event SalaryStreamStarted(address indexed employee, uint256 cycleStart); 
    event SalaryCashedOut(address indexed employee, uint256 amount); 
    event StreamingStopped(address indexed employee); 


    // Custom Errors
    error NotManager(); 
    error StreamingNotActive(); 
    error InsufficientBalance(uint256 available, uint256 requested);
    

    /// @notice Constructor to set the manager address on contract deployment
    constructor() {
        manager = msg.sender;  
    }

    /// @notice Modifier to restrict function access to only the manager
    modifier onlyManager() {
        if (msg.sender != manager) revert NotManager();
        _;
    }

    /// @notice Modifier to ensure salary streaming is active for the employee
    modifier streamingActive(address employee) {
        if (!isStreaming[employee]) revert StreamingNotActive();
        _;
    }

    /// @notice Allows the manager to set the start of the salary cycle for an employee
    /// @param employee The address of the employee
    /// @param cycleStart The timestamp of when the salary cycle should begin
    function setSalaryCycle(address employee, uint256 cycleStart) public onlyManager {
        employeeSalaryCycleStart[employee] = cycleStart; 
        isStreaming[employee] = true;   
        emit SalaryStreamStarted(employee, cycleStart); 
    }


    /// @notice Allows the employee to withdraw their accrued salary
    function cashOut() public streamingActive(msg.sender) {
        // Calculate time passed since the beginning of salary cycle
        uint256 timePassed = block.timestamp - employeeSalaryCycleStart[msg.sender]; 
        uint256 salaryOwed =  timePassed * SALARY_PER_SECOND; 

         // Ensure the employee has enough balance to withdraw
        if (salaryOwed > employeeBalance[msg.sender]) {
           revert InsufficientBalance(employeeBalance[msg.sender], salaryOwed); 
        }


        employeeBalance[msg.sender] -= salaryOwed; 

         // Transfer funds to the employee
        (bool success, ) = payable(msg.sender).call{value: salaryOwed}(""); 
        require(success, "Transfer failed"); 

        emit SalaryCashedOut(msg.sender, salaryOwed);
    }


    /// @notice Allows the manager to stop the salary streaming for an employee
    /// @param employee The address of the employee
    function stopStreaming(address employee) public onlyManager {
        isStreaming[employee] = false;
        emit StreamingStopped(employee); 
    }
}