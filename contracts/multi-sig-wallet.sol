// SPDX-License-Identifier: MIT

contract multiSigWallet {
    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    struct Transaction {
        address to;
         uint256 value;
        bytes data;
        bool executed;
    }
    /* state variables */
    address[] public owners;
    uint256 public required;  //no. of approvals required to  execute the tx
    mapping (address => bool) public isOwner; //ownerAddress => true/false
    mapping (uint256 => mapping(address => bool)) public approvals; //store the approvals of each tx by each owner ( Tx_index => ownerAddress => ture/false) [tx is approved by owner or not]

    Transaction[] public transactions; 

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    modifier txExist(uint256 _txId) {
        require(_txId < transactions.length, "Tx not exist");
        _;
    }
    modifier notApproved(uint256 _txId) {
        require(!approvals[_txId][msg.sender], "tx already approved");
        _;
    }
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }
     
    constructor(address[] memory _owners, uint256 _require) {
        require(_owners.length > 0, "owner required");
        require(_require > 0 && _require <= _owners.length, "invalid required number of owner");
        for(uint256 i = 0; i< _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),  "invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _require;   
    }
    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }
    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
             to: _to,
             value: _value,
             data: _data,
             executed: false
        }));
        emit SubmitTransaction (transactions.length - 1);
    }
    function approve(uint256 _txId) external onlyOwner txExist(_txId) notApproved(_txId) notExecuted(_txId) {
        approvals[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }
    function _getApprovalCount(uint256 _txId) private view returns(uint256 count){
        for(uint256 i = 0; i < owners.length; i++){
            if(approvals[_txId][owners[i]]){
                count += 1;
            }
        }
    }
    function execute(uint256 _txId) external txExist(_txId) notExecuted(_txId){
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        emit Execute (_txId);
    }
    function reveoke(uint256 _txId) external onlyOwner() txExist(_txId) notExecuted(_txId){
        require(approvals[_txId][msg.sender], "tx not approved");
        approvals[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}