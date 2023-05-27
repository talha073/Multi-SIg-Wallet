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
}