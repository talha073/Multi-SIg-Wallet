// SPDX-License-Identifier: MIT
contract multiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(uint indexed txIndex);
    event Approve(address indexed owner, uint indexed txIndex);
    event Revoke(address indexed owner, uint indexed txIndex);
    event Execute(address indexed owner, uint indexed txIndex);
    
    
    constructor() {
        
    }
}