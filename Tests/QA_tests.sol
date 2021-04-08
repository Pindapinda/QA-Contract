pragma solidity >=0.7.0 <0.9.0;
import "../contracts/QA_Contract.sol";

// DataAsset Tests
contract DAssetTest {
    DataAsset FreeDAsset;
    DataAsset DAssetToTest;
    NonOwner TestNonOwner;

    constructor() payable{}

    // 1. Create Data Assets
    function create_DAs() public returns(address free, address toTest) {
        FreeDAsset = new DataAsset(0);
        DAssetToTest = new DataAsset(10);
        TestNonOwner = new NonOwner();
        free = address(FreeDAsset);
        toTest = address(DAssetToTest);
    }

    // 2. Register Data Asset as non-owner (Should fail)
    function nonOwnedRegister() public {
        TestNonOwner.falseRegister(address(DAssetToTest));
    }

    // 3. Register Data Asset on non-existing QA_contract. (Should fail)
    function nonExistingRegister() public {
        DAssetToTest.register(address(0));
    }

    // 4. Withdraw as owner when balance is 0
    // 11. Withdraw as owner when balance is 10.
    function ownedWithdraw() public {
        uint balanceBefore = address(this).balance;
        uint withdrawable = address(DAssetToTest).balance;
        DAssetToTest.withdraw();
    }

    // 5. Withdraw as non-owner when balance is 0 (Should Fail!)
    // 10. Withdraw as non-owner when balance is 10. (Should Fail!)
    function nonOwnedWithdraw() public {
        TestNonOwner.falseWithdraw(address(DAssetToTest));
    }

    // 6. Pay fee incorrectly when price is 0 (Should fail!)
    function payIncorrectZero() public {
        payable(FreeDAsset).transfer(uint(10));
    }

    // 7. Pay fee correctly when price is 0.
    function payZero() public {
        uint balanceBefore = address(FreeDAsset).balance;
        payable(FreeDAsset).transfer(uint(0));
    }

    // 8. Pay fee incorrectly when price is 10 (should fail!)
    function payIncorrect() public {
        payable(DAssetToTest).transfer(uint(1));
    }

    // 9. Pay fee correctly when price is 10.
    function payFee() public {
        payable(DAssetToTest).transfer(uint(10));
    }
}

// QA Tests
contract QATest{
    QA QAToTest;
    DataAsset TestDAsset;
    DataAsset NonBoughtDAsset;
    StakerContract TestStaker;
    StakerContract NonRegisteredStaker;

    // struct Staker {
    //     bool registered;
    //     uint value;
    //     mapping(address => bool) bought;
    //     mapping(address => uint256) staked;
    // }

    constructor() payable {}

    function get_QA() public view returns(address){
        return address(QAToTest);
    }

    function get_Staker() public view returns(address){
        return address(TestStaker);
    }

    function get_DataAsset() public view returns(address){
        return address(TestDAsset);
    }

    // 1. Create QA_Contract.
    function createContracts() public returns(address qa) {
        QAToTest = new QA();
        TestDAsset = new DataAsset(10);
        NonBoughtDAsset = new DataAsset(10);
        TestStaker = new StakerContract{value: 100 wei}(address(QAToTest));
        NonRegisteredStaker = new StakerContract{value: 100 wei}(address(QAToTest));
        qa = address(QAToTest);
    }

    // 2. Register Data Asset
    // 3. Register same Data Asset again (Should fail).
    function registerDA() public {
        TestDAsset.register(payable(address(QAToTest)));
        NonBoughtDAsset.register(payable(address(QAToTest)));
    }

    // 4. Register as Staker
    // 5. Register again as same Staker (should fail).
    function registerStaker() public {
        TestStaker.register();
    }

    // 6. Buy asset as non-registered staker (Should fail).
    function unregisteredBuy() public {
        NonRegisteredStaker.buy(address(TestDAsset), uint(0));
    }

    // 7. Buy asset when value != price (Should fail).
    function buyValueNotPrice() public {
        TestStaker.buy{value: 10 wei}(address(TestDAsset), uint(0));
    }

    // 8. Buy asset when value==price!=price asked by Data Asset (Should fail).
    function buyWrongPrice() public {
        TestStaker.buy{value: 0 wei}(address(TestDAsset), uint(0));
    }

    // 9.Buy asset.
    function successfullBuy() public {
        TestStaker.buy{value: 10 wei}(address(TestDAsset), uint(10));
    }

    // 10. Stake as non-registered staker (Should fail).
    function nonRegisteredStake() public {
        NonRegisteredStaker.stake{value : 20 wei}(address(TestDAsset));
    }

    // 11. Stake as registered staker on non-bought asset (Should fail).
    function nonBoughtStake() public {
        TestStaker.stake{value : 20 wei}(address(NonBoughtDAsset));
    }

    // 12. Stake as registered staker on bought asset.
    // 13. Stake again on same asset.
    function successfullStake() public {
        TestStaker.stake{value : 20 wei}(address(TestDAsset));
    }

    // 14. Receive fee with non-registered data asset (Should fail).
    function nonRegisteredDAReceive() public {
        QAToTest.receive_fee{value: 30 wei}(address(this), address(TestStaker));
    }

    // 15. Receive fee with registered data asset and non-registered staker (Should fail).
    function nonRegisteredStakerReceive() public {
        QAToTest.receive_fee{value: 30 wei}(address(TestDAsset), address(NonRegisteredStaker));
    }

    // 16. Receive fee with registered data asset, registered staker and non-bought data asset (Should fail).
    function nonBoughtReceive() public {
        QAToTest.receive_fee{value: 30 wei}(address(NonBoughtDAsset), address(TestStaker));
    }

    // 17. Receive fee with registered data asset, registered staker and bought data asset.
    function succesfullReceive() public {
        QAToTest.receive_fee{value: 30 wei}(address(TestDAsset), address(TestStaker));
    }

    // 18. Withdraw stake as non-registered staker (Should fail).
    function nonRegisteredWithdraw() public {
        NonRegisteredStaker.withdraw(address(TestDAsset), uint(0));
    }

    // 19. Withdraw stake as registered staker with non-bought DAsset (Should fail)
    function nonBoughtWithdraw() public {
        TestStaker.withdraw(address(NonBoughtDAsset), uint(0));
    }

    // 20. Withdraw stake as registered staker with bought DAsset, 0 staked and amount > 0 (Should fail).
    function nonStakedWithdraw() public {
        TestStaker.buy{value: 10 wei}(address(NonBoughtDAsset), uint(10));
        TestStaker.withdraw(address(NonBoughtDAsset), uint(1));
    }

    // 21. Withdraw stake as registered staker with bought DAsset, 40 staked and amount > 70 (Should fail).
    function tooHighWithdraw() public {
        TestStaker.withdraw(address(TestDAsset), uint(100));
    }

    // 22. Withdraw stake as registered staker with bought DAsset and staked == amount.
    function successfullWithdraw() public {
        TestStaker.withdraw(address(TestDAsset), uint(40));
    }
}

contract NonOwner {
    DataAsset notOwnedDA;

    function falseRegister(address DAsset) public {
        notOwnedDA = DataAsset(payable(DAsset));
        notOwnedDA.register(payable(DAsset));
    }

    function falseWithdraw(address DAsset) public {
        notOwnedDA = DataAsset(payable(DAsset));
        notOwnedDA.withdraw();
    }
}

contract StakerContract {
    QA stakerQA;

    constructor(address QAContract) payable{
        stakerQA = QA(payable(QAContract));
    }

    function register() public{
        stakerQA.register_staker();
    }

    function buy(address DAsset, uint price) public payable {
        stakerQA.buy_asset{value: msg.value}(payable(DAsset), price);
    }

    function stake(address DAsset) public payable {
        stakerQA.stake{value: msg.value}(DAsset);
    }

    function withdraw(address DAsset, uint amount) public {
        stakerQA.withdraw_stake(DAsset, amount);
    }

    receive() external payable {}
}
