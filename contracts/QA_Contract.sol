pragma solidity >=0.7.0 <0.9.0;

contract DataAsset{
    address public owner;
    uint256 public price;

    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }

    constructor(uint256 _price){
        owner = msg.sender;
        price = _price;
    }

    function register(address QA_address) public onlyOwner{
        QA deployed_QA = QA(QA_address);
        deployed_QA.register_dasset();
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    fallback () external payable {
        require(msg.value==price, "Please pay the exact price of this contract");
    }
}


contract QA {
    struct Staker {
        bool registered;
        uint value;
        mapping(address => bool) bought;
        mapping(address => uint256) staked;
    }

    mapping(address => bool) public DAssets;
    mapping(address => Staker) public stakers;

    modifier onlyStaker{
        require(stakers[msg.sender].registered, "This function can only be called be registered stakers!");
        _;
    }

    function register_dasset() public {
        require(!DAssets[msg.sender], "This address has already registered as a Data Asset!");
        DAssets[msg.sender] = true;
    }

    function register_staker() public {
        require(!stakers[msg.sender].registered, "This address has already registered as a staker!"); // A staker should not register twice as that would reset their balance.
        Staker storage s = stakers[msg.sender];
        s.registered = true;
        s.value = 0;
    }

    function buy_asset(address payable DAsset, uint price) payable public onlyStaker{
        require(DAssets[DAsset], "No registered Data Asset found!");
        require(msg.value==price);
        DAsset.transfer(price); // Does this work? What happens if the fallback function throws?
        stakers[msg.sender].bought[DAsset] = true;
    }

    function stake(address DAsset) payable public onlyStaker{
        require(stakers[msg.sender].bought[DAsset]);
        stakers[msg.sender].staked[DAsset] += msg.value;
        stakers[msg.sender].value += msg.value;
    }

    function receive_fee(address DAsset, address staker) payable public{
        require(DAssets[DAsset]); // Data Asset must be registered.
        require(stakers[staker].staked[DAsset] > 0); // Staker must have some stake in the data asset if they are to be rewarded.
        stakers[staker].staked[DAsset] += msg.value; // Stakers fee is added to original stake.
        stakers[staker].value += msg.value;
    }

    function withdraw_stake(address DAsset, uint amount) public onlyStaker{
        require(stakers[msg.sender].staked[DAsset] >= amount); // Can never withdraw more than current stake
        stakers[msg.sender].staked[DAsset] -= amount;
        stakers[msg.sender].value -= amount;
        payable(msg.sender).transfer(amount);
    }
}
