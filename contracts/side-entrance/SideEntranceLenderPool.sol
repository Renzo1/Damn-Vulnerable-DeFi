// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    mapping(address => uint256) private balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    // @note deposit tokens
    function deposit() external payable {
        // @audit doesn't check if the tokens are actually sent
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    // @note withdraw tokens
    function withdraw() external {
        // @note cache balance caller
        // All callers balance is withdrawn at once
        uint256 amount = balances[msg.sender];

        // @note Clear users balance
        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    // @note flashloan tokens
    // @audit no reentrancy guard
    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        // @audit External interact
        // @audit function can be re-entered
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        // @audit reliance on address(this).balance to check returned value
        // Should have used an internal account system instead
        if (address(this).balance < balanceBefore)
            revert RepayFailed();
    }
    /* Strategy
    - flashLoan all the ETH balance
    - Deposit in thesame Tx
    - Then withdraw
    */

}
