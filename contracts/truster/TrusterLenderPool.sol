// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableToken.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    // @audit I get to specify the borrowe and target address which can be arbitrary addresses.
    // @q what happens if the borrower and target addresses are different?
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        // @audit caches the contract's balance of the token
        uint256 balanceBefore = token.balanceOf(address(this));

        // @audit transfers amount of tokens to borrower
        token.transfer(borrower, amount);

        // @audit then makes an external call to an arbitrary address with an arbitrary data
        // Can I transferFrom this account? Yes
        // Get this contract to approve us to spend its token
        target.functionCall(data);

        // @audit checks if the contract's balance after the borrowers transaction is less than the initial balance
        // and reverts if true.
        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }

    /* Attack Strategy Ideas
    Noobs:
    - Ext call to an arbitrary address
    - A
    */
}
