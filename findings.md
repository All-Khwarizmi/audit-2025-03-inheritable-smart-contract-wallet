### [S-#] Some functions do not update the deadline which can lead to allowing inheritance despite owner interactions

**Description:**
There's inconsistency in updating the deadline. Check the following functions: (in green are the functions that update the deadline and in red are the functions that do not)

```diff
+ InheritanceManager::sendERC20
+ InheritanceManager::sendETH
+ InheritanceManager::addBeneficiery
- InheritanceManager::contractInteractions
- InheritanceManager::createEstateNFT
- InheritanceManager::removeBeneficiary
```

**Impact:**
If the owner only call the functions that do not update the deadline like `InheritanceManager::contractInteractions` or `InheritanceManager::createEstateNFT` it can lead to allowing inheritance despite owner interactions which breaks the core purpose of the contract.

**Proof of Concept:**

**Recommended Mitigation:**

### [S-#] Passing an address that is not in the beneficiaries array to `InheritanceManager::removeBeneficiary` will silently remove the first element in the array

**Description:**
When passing an address that is not in the beneficiaries array to `InheritanceManager::removeBeneficiary`, the function will silently remove the first element in the array.

**Impact:**
Removing the first element of the beneficiaries array without the owner noticing it. This highly affects all the inheritance logic:

- If the owner is the only beneficiary, the owner will lose access to the funds.
- If the owner is not the only beneficiary, the first beneficiary will lose access to the funds.

**Proof of Concept:**

1. Add the following getter to `InheritanceManager.sol`

```javascript
    function getBeneficiary(uint256 _index) public view returns (address) {
        return beneficiaries[_index];
    }
```

2. Add the following test to `InheritanceManager.t.sol`

```javascript
    function test_removeFirstBeneficiaryByPassingInexistentIndex() public {
        address user2 = makeAddr("user2");
        address inexistentUser = makeAddr("inexistentUser");

        vm.startPrank(owner);

        im.addBeneficiery(user1);
        im.addBeneficiery(user2);

        assertEq(user1, im.getBeneficiary(0)); // user1 is the first beneficiary
        assertEq(user2, im.getBeneficiary(1));

        im.removeBeneficiary(inexistentUser); // inexistentUser is not in the beneficiaries array
        vm.stopPrank();

        assert(user1 != im.getBeneficiary(0)); // user1 is not the first beneficiary anymore
    }
```

3. run the test

```bash
$ forge test --mt test_removeFirstBeneficiaryByPassingInexistentIndex
```

**Recommended Mitigation:**
We recommend adding a check to `InheritanceManager::removeBeneficiary` to ensure that the address is in the array.

1. check if the address is in the array, if not, revert

```javascript
    function removeBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiariesContains(_beneficiary), "InheritanceManager: beneficiary does not exist");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] == _beneficiary) {
                beneficiaries[i] = beneficiaries[beneficiaries.length - 1];
                beneficiaries.pop();
                break;
            }
        }
        _setDeadline();
    }

    function _beneficiariesContains(address _beneficiary) internal view returns (bool) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] == _beneficiary) {
                return true;
            }
        }
        return false;
    }
```

2. Add a getter to check if a beneficiary is in the array or/and the length of the array

```javascript
    function getBeneficiary(uint256 _index) public view returns (address) {
        return beneficiaries[_index];
    }
```

### [S-#] `InheritanceManager::addBeneficiery` allows adding the same address multiple times allowing duplicates in the beneficiaries array. This can lead to bad proportions in the inheritance

**Description:**
When passing an address that is already in the beneficiaries array to `InheritanceManager::addBeneficiery`, the function will append the address to the end of the array, creating a duplicate. This can lead to bad proportions in the inheritance.

**Impact:**
Having the same beneficiary multiple times in the array results in the beneficiary receiving a bigger share of the funds than expected. This breaks the core assumption of the funds being distributed equally.

**Proof of Concept:**

1. Add the following test to `InheritanceManager.t.sol`
   > In this we add the `user1` twice.
   > We calculate the proportion of the funds that should be received by dividing the total funds by the number of beneficiaries + 1 (accounting for the duplicate of `user1`).
   > We assert that the `user1` gets 2 times the proportion of the funds while the other get 1 proportion.

```javascript
       function test_withdrawInheritedFundsEtherDuplicateBeneficiary() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 9e18);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();
        uint256 proportion = 9e18 / 4;
        assertEq(proportion * 2, user1.balance);
        assertEq(proportion, user2.balance);
        assertEq(proportion, user3.balance);
    }
```

2. run the test

```bash
$ forge test --mt test_withdrawInheritedFundsEtherDuplicateBeneficiary
```

**Recommended Mitigation:**
We recommend adding a check to `InheritanceManager::addBeneficiery` to ensure that the address is not already in the array.

```javascript
    function addBeneficiery(address _beneficiary) external onlyOwner {
        require(!_beneficiariesContains(_beneficiary), "InheritanceManager: beneficiary already exists");

        beneficiaries.push(_beneficiary);
        _setDeadline();
    }

    function _beneficiariesContains(address _beneficiary) internal view returns (bool) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] == _beneficiary) {
                return true;
            }
        }
        return false;
    }
```

### [S-#] TITLE (Root Cause + Impact)

**Description:**

**Impact:**

**Proof of Concept:**

**Recommended Mitigation:**
