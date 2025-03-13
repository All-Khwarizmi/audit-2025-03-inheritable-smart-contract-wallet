# Missing Deadline Updates Vulnerability Report

## Original Format (For Your Report)

### [H-1] Missing deadline updates in owner functions breaks inheritance timelock protection

**Description:**
Multiple owner-callable functions don't reset the inheritance timelock deadline, violating the core requirement that "EVERY transaction the owner does with this contract must reset the 90 days timer." The inconsistency is evident in the following functions:

```diff
+ InheritanceManager::sendERC20
+ InheritanceManager::sendETH
+ InheritanceManager::addBeneficiery
- InheritanceManager::contractInteractions
- InheritanceManager::createEstateNFT
- InheritanceManager::removeBeneficiary
```

**Impact:**
The impact is severe as it undermines the core security model of the contract:

- Beneficiaries can gain access to funds while the owner is still active
- The owner could lose funds despite regular contract interaction
- This breaks the stated invariant that all owner activity should reset the timelock

If the owner only calls the functions that do not update the deadline like `InheritanceManager::contractInteractions` or `InheritanceManager::createEstateNFT`, beneficiaries could inherit funds prematurely, despite recent owner interactions.

**Proof of Concept:**

1. Add the following test to `InheritanceManager.t.sol`

```solidity
function test_inheritanceManagerInteractionsUpdateDeadline() public {
        address user2 = makeAddr("user2");

        // First add beneficiary and roll to 90 days and check the deadline
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        vm.stopPrank();

        vm.warp(90 days);
        assertEq(1 + 90 days, im.getDeadline());
        vm.prank(user1);
        vm.expectRevert(InheritanceManager.InactivityPeriodNotLongEnough.selector);
        im.inherit();

        // Now call the functions that do not update the deadline
        vm.startPrank(owner);
        vm.warp(1 + 100 days);
        im.contractInteractions(address(0), abi.encode(address(0)), 0, false);
        vm.warp(1 + 120 days);
        im.createEstateNFT("our beach-house", 2000000, address(usdc));
        vm.stopPrank();

        // The deadline has not being updated
        assertEq(1 + 90 days, im.getDeadline());
        assertEq(vm.getBlockTimestamp(), 1 + 120 days);

        vm.prank(user1);
        im.inherit();

        assertEq(true, im.getIsInherited());
    }
```

2. run the test

```bash
 forge test --mt test_inheritanceManagerInteractionsUpdateDeadline
```

**Recommended Mitigation:**
Add the `_setDeadline()` function call to all owner-only functions to ensure consistent deadline updates:

```diff
function contractInteractions(address _target, bytes calldata _payload, uint256 _value, bool _storeTarget)
    external
    nonReentrant
    onlyOwner
{
    (bool success, bytes memory data) = _target.call{value: _value}(_payload);
    require(success, "interaction failed");
    if (_storeTarget) {
        interactions[_target] = data;
    }
+   _setDeadline();
}

function createEstateNFT(string memory _description, uint256 _value, address _asset) external onlyOwner {
    uint256 nftID = nft.createEstate(_description);
    nftValue[nftID] = _value;
    assetToPay = _asset;
+   _setDeadline();
}

function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove];
+   _setDeadline();
}
```

## CodeHawks Format

## [H-1] Missing deadline updates in owner functions breaks inheritance timelock protection

## Summary

Multiple owner-callable functions don't reset the inheritance timelock deadline, allowing premature inheritance even when the owner is actively using the contract. This directly violates the project's first core assumption: "EVERY transaction the owner does with this contract must reset the 90 days timer."

## Vulnerability Details

The InheritanceManager contract uses a deadline-based system to determine when beneficiaries can inherit funds. This deadline should be extended whenever the owner interacts with the contract. However, three important owner functions fail to reset the deadline:

```solidity
function contractInteractions(address _target, bytes calldata _payload, uint256 _value, bool _storeTarget)
    external
    nonReentrant
    onlyOwner
{
    (bool success, bytes memory data) = _target.call{value: _value}(_payload);
    require(success, "interaction failed");
    if (_storeTarget) {
        interactions[_target] = data;
    }
    // Missing _setDeadline() call
}

function createEstateNFT(string memory _description, uint256 _value, address _asset) external onlyOwner {
    uint256 nftID = nft.createEstate(_description);
    nftValue[nftID] = _value;
    assetToPay = _asset;
    // Missing _setDeadline() call
}

function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove];
    // Missing _setDeadline() call
}
```

This inconsistency means an owner could interact with their wallet regularly but still have their funds inherited by beneficiaries if they only use these specific functions.

## Impact

The impact is severe as it undermines the core security model of the contract:

- Beneficiaries can gain access to funds while the owner is still active
- The owner could lose funds despite regular contract interaction
- This breaks the stated invariant that all owner activity should reset the timelock

The proof of concept test demonstrates that even after multiple owner interactions, the inheritance process can still be triggered because the deadline was never updated.

## Tools Used

Manual code review and Foundry testing framework

## Recommendations

Add the `_setDeadline()` function call to all owner-only functions to ensure consistent deadline updates:

```diff
function contractInteractions(address _target, bytes calldata _payload, uint256 _value, bool _storeTarget)
    external
    nonReentrant
    onlyOwner
{
    (bool success, bytes memory data) = _target.call{value: _value}(_payload);
    require(success, "interaction failed");
    if (_storeTarget) {
        interactions[_target] = data;
    }
+   _setDeadline();
}

function createEstateNFT(string memory _description, uint256 _value, address _asset) external onlyOwner {
    uint256 nftID = nft.createEstate(_description);
    nftValue[nftID] = _value;
    assetToPay = _asset;
+   _setDeadline();
}

function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove];
+   _setDeadline();
}
```

# Duplicate Beneficiaries Vulnerability Report

## Original Format (For Your Report)

### [M-1] Duplicate beneficiaries in `InheritanceManager::addBeneficiery` leads to uneven inheritance distribution

**Description:**
The `InheritanceManager::addBeneficiery` function does not check if a beneficiary already exists in the array before adding them. This allows the same address to be added multiple times, creating duplicates in the beneficiaries array. When inheritance occurs, funds are distributed based on the number of entries in this array, not unique addresses.

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    // Missing check for existing beneficiary
    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

**Impact:**
This vulnerability breaks a core assumption of equal fund distribution among beneficiaries. A beneficiary added multiple times will receive a disproportionately larger share of the inheritance:

- If added twice, they'll receive double their intended share
- If added three times, they'll receive triple their intended share
- This reduces the inheritance share of other legitimate beneficiaries
- Could be exploited intentionally to favor certain beneficiaries

**Proof of Concept:**

1. Add the following test to `InheritanceManager.t.sol`
   > This test adds `user1` twice. We calculate the proportion of funds by dividing the total funds by the number of beneficiaries (4 entries for 3 unique addresses).
   > We then assert that `user1` gets twice the proportion while other users get one proportion each.

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

2. Run the test

```bash
$ forge test --mt test_withdrawInheritedFundsEtherDuplicateBeneficiary
```

**Recommended Mitigation:**
Implement a check in the `addBeneficiery` function to prevent duplicate entries:

```solidity
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

## CodeHawks Format

## [M-1] Duplicate beneficiaries in `addBeneficiery` function breaks equal inheritance distribution

## Summary

The `InheritanceManager` contract does not prevent the same address from being added multiple times as a beneficiary. This vulnerability allows certain beneficiaries to receive a larger share of the inheritance than intended, breaking the contract's core assumption of equal fund distribution.

## Vulnerability Details

The `addBeneficiery` function lacks a check to prevent adding duplicate beneficiary addresses:

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    // No check to see if this address already exists in the array
    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

The `withdrawInheritedFunds` function distributes funds based on the length of the beneficiaries array:

```solidity
function withdrawInheritedFunds(address _asset) external {
    if (!isInherited) {
        revert NotYetInherited();
    }
    uint256 divisor = beneficiaries.length;
    // Funds are divided by the number of entries, not unique addresses
    if (_asset == address(0)) {
        uint256 ethAmountAvailable = address(this).balance;
        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
        for (uint256 i = 0; i < divisor; i++) {
            address payable beneficiary = payable(beneficiaries[i]);
            (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
            require(success, "something went wrong");
        }
    } else {
        // Same issue for ERC20 tokens
        // ...
    }
}
```

When a beneficiary appears multiple times in the array, they will receive multiple shares of the inheritance, creating an unfair distribution.

## Impact

This vulnerability directly impacts the fairness of inheritance distribution:

1. Beneficiaries added multiple times receive a proportionally larger share of the inheritance
2. Other legitimate beneficiaries receive less than their intended share
3. This could be exploited intentionally to favor certain beneficiaries
4. Violates the core contract functionality of equal distribution

The impact is rated as medium because:

- It does not directly lead to fund loss for the contract
- But it does lead to incorrect fund distribution
- It breaks the core assumption of equal distribution

## Tools Used

Manual code review and Foundry testing

## Proof of Concept

1. Add the following test to `InheritanceManager.t.sol`
   > This test adds `user1` twice. We calculate the proportion of funds by dividing the total funds by the number of beneficiaries (4 entries for 3 unique addresses).
   > We then assert that `user1` gets twice the proportion while other users get one proportion each.

```solidity
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

2. Run the test

```bash
$ forge test --mt test_withdrawInheritedFundsEtherDuplicateBeneficiary
```

## Recommendations

Implement a check to prevent duplicate beneficiary addresses:

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "InheritanceManager: zero address");

    // Check for duplicates
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            revert("InheritanceManager: beneficiary already exists");
        }
    }

    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

Alternatively, implement a helper function for reusability:

```solidity
function _beneficiariesContains(address _beneficiary) internal view returns (bool) {
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            return true;
        }
    }
    return false;
}

function addBeneficiery(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "InheritanceManager: zero address");
    require(!_beneficiariesContains(_beneficiary), "InheritanceManager: beneficiary already exists");
    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

# Remove Beneficiary Silent Issue Report

## Original Format (For Your Report)

### [M-1] Passing a non-existent address to `InheritanceManager::removeBeneficiary` silently removes the first beneficiary

**Description:**
When passing an address that is not in the beneficiaries array to `InheritanceManager::removeBeneficiary`, the function will silently remove the first element in the array. This happens because the `_getBeneficiaryIndex` function returns 0 (the default value for uint256) when the address is not found, causing the function to delete the beneficiary at index 0.

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove]; // Will remove index 0 if _beneficiary is not found
}

function _getBeneficiaryIndex(address _beneficiary) public view returns (uint256 _index) {
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (_beneficiary == beneficiaries[i]) {
            _index = i;
            break;
        }
    }
    // If address not found, returns 0 (default value for uint256)
}
```

**Impact:**
This vulnerability has severe consequences for inheritance management:

- If the owner is the only beneficiary, they will lose access to the funds without any warning
- If there are multiple beneficiaries, the first beneficiary will be silently removed from the inheritance list
- Funds could be inherited by the wrong parties as a result
- The function doesn't revert or emit an event, so the owner has no way to detect this error

**Proof of Concept:**

1. Add the following test to `InheritanceManager.t.sol`

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

2. Run the test

```bash
$ forge test --mt test_removeFirstBeneficiaryByPassingInexistentIndex
```

**Recommended Mitigation:**
Modify the `removeBeneficiary` function to check if the address exists in the array and revert if it doesn't:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    // Check if beneficiary exists
    bool found = false;
    uint256 indexToRemove = 0;

    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            indexToRemove = i;
            found = true;
            break;
        }
    }

    require(found, "InheritanceManager: beneficiary does not exist");

    // Remove and rearrange for gas efficiency
    beneficiaries[indexToRemove] = beneficiaries[beneficiaries.length - 1];
    beneficiaries.pop();

    // Add deadline update - currently missing
    _setDeadline();
}
```

Additionally, add a helper function and getter to improve contract usability:

```solidity
function isBeneficiary(address _address) public view returns (bool) {
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _address) {
            return true;
        }
    }
    return false;
}

function getBeneficiariesCount() public view returns (uint256) {
    return beneficiaries.length;
}
```

## CodeHawks Format

## [M-1] Silent removal of first beneficiary when non-existent address is passed to removeBeneficiary

## Summary

The `removeBeneficiary` function silently removes the first beneficiary when attempting to remove an address that doesn't exist in the beneficiaries array. This occurs because the `_getBeneficiaryIndex` helper function returns 0 (the default value for uint256) when the specified address isn't found, causing the function to delete the beneficiary at index 0 without any error or warning.

## Vulnerability Details

The vulnerability exists in the interaction between the `removeBeneficiary` function and its helper function `_getBeneficiaryIndex`:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove];
}

function _getBeneficiaryIndex(address _beneficiary) public view returns (uint256 _index) {
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (_beneficiary == beneficiaries[i]) {
            _index = i;
            break;
        }
    }
    // No explicit return if address not found, so _index defaults to 0
}
```

When `_beneficiary` is not found in the array, the function completes without setting `_index`, which means it retains its default value of 0. The calling function then blindly uses this index to delete an entry, removing the first beneficiary rather than the intended one.

Additionally, there are two further issues in this function:

1. It uses `delete` on an array element which sets it to the default value (address(0)) but doesn't remove the element from the array
2. It doesn't call `_setDeadline()` to update the inactivity timer

## Impact

This vulnerability has serious consequences for the inheritance management:

1. Unintended removal of legitimate beneficiaries
2. Loss of inheritance rights for the first beneficiary without any notification
3. If owner is the only beneficiary (in backup wallet scenario), could result in complete loss of fund access
4. No error message or event to indicate the failure
5. The contract state becomes inconsistent with the owner's intentions

The impact is rated as medium because:

- It doesn't directly lead to immediate loss of funds
- But it could result in fund distribution to wrong parties during inheritance
- It fundamentally breaks a key contract mechanism

## Tools Used

Manual code review and Foundry testing

## Proof of Concept

1. Add the following test to `InheritanceManager.t.sol`

```solidity
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

2. Run the test

```bash
forge test --mt test_removeFirstBeneficiaryByPassingInexistentIndex
```

## Recommendations

1. Modify the `removeBeneficiary` function to check if the address exists in the array:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    bool found = false;
    uint256 indexToRemove = 0;

    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            indexToRemove = i;
            found = true;
            break;
        }
    }

    require(found, "InheritanceManager: beneficiary not found");

    // Use swap and pop pattern for efficient removal
    beneficiaries[indexToRemove] = beneficiaries[beneficiaries.length - 1];
    beneficiaries.pop();

    // Reset deadline
    _setDeadline();
}
```

2. Also implement utility functions to make the contract more user-friendly:

```solidity
// Check if an address is a beneficiary
function isBeneficiary(address _address) public view returns (bool) {
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _address) {
            return true;
        }
    }
    return false;
}

// Get total number of beneficiaries
function getBeneficiariesCount() public view returns (uint256) {
    return beneficiaries.length;
}
```

# Zero Address Vulnerability Report

## Original Format (For Your Report)

### [M-1] Lack of zero address validation in beneficiary management can lead to permanent fund loss

**Description:**
The `InheritanceManager` contract doesn't validate against zero addresses when adding beneficiaries. Additionally, when removing beneficiaries, it uses `delete` which sets the value to the zero address without removing the entry from the array. This can lead to funds being distributed to the zero address (effectively burning them) when inheritance occurs.

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    // No check for zero address
    beneficiaries.push(_beneficiary);
    _setDeadline();
}

function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    // This sets the element to address(0) but keeps it in the array
    delete beneficiaries[indexToRemove];
}
```

The `withdrawInheritedFunds` function will then attempt to send funds to all addresses in the array, including zero addresses:

```solidity
function withdrawInheritedFunds(address _asset) external {
    // ...
    for (uint256 i = 0; i < divisor; i++) {
        address payable beneficiary = payable(beneficiaries[i]);
        (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
        require(success, "something went wrong");
    }
    // ...
}
```

**Impact:**
This vulnerability can lead to several adverse outcomes:

- Funds can be permanently lost by being sent to address(0)
- Using `delete` on array elements doesn't reduce the array size, leading to confusion about the actual number of beneficiaries
- The inheritance share calculation becomes inaccurate if the array contains zero addresses
- In some cases, the contract might revert when trying to send ETH to address(0), preventing any beneficiary from receiving their inheritance

**Proof of Concept:**

1. Add the following test to `InheritanceManager.t.sol`

```solidity
function test_zeroAddressBeneficiaryFundLoss() public {
    address user2 = makeAddr("user2");

    vm.startPrank(owner);
    // Add a valid beneficiary
    im.addBeneficiery(user1);
    // Add the zero address as a beneficiary
    im.addBeneficiery(address(0));
    // Add another valid beneficiary
    im.addBeneficiery(user2);

    // Fund the contract
    vm.deal(address(im), 3 ether);
    vm.stopPrank();

    // Wait for inheritance timelock to expire
    vm.warp(block.timestamp + 91 days);

    // Trigger inheritance
    vm.prank(user1);
    im.inherit();

    // Try to withdraw funds - this will attempt to send 1 ETH to address(0)
    vm.prank(user1);
    // This may revert or burn 1 ETH depending on the environment
    try im.withdrawInheritedFunds(address(0)) {
        // If it succeeds, check that 1 ETH was sent to address(0) (effectively burned)
        assertEq(address(0).balance, 1 ether);
        assertEq(user1.balance, 1 ether);
        assertEq(user2.balance, 1 ether);
    } catch {
        // If it reverts, no one gets their funds
        assertEq(address(im).balance, 3 ether);
        assertEq(user1.balance, 0);
        assertEq(user2.balance, 0);
    }
}
```

2. Run the test

```bash
$ forge test --mt test_zeroAddressBeneficiaryFundLoss
```

**Recommended Mitigation:**
Add zero address validation to the `addBeneficiery` function:

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "InheritanceManager: zero address not allowed");

    // Check for duplicates (addressing another issue)
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            revert("InheritanceManager: beneficiary already exists");
        }
    }

    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

For `removeBeneficiary`, instead of using `delete`, use the swap-and-pop pattern to actually remove the element from the array:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    // Find the beneficiary
    bool found = false;
    uint256 indexToRemove = 0;

    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            indexToRemove = i;
            found = true;
            break;
        }
    }

    require(found, "InheritanceManager: beneficiary not found");

    // Swap with the last element and pop
    beneficiaries[indexToRemove] = beneficiaries[beneficiaries.length - 1];
    beneficiaries.pop();

    _setDeadline();
}
```

Additionally, add a check in `withdrawInheritedFunds` to ensure no funds are sent to address(0):

```solidity
function withdrawInheritedFunds(address _asset) external {
    // ...
    for (uint256 i = 0; i < divisor; i++) {
        address beneficiary = beneficiaries[i];
        if (beneficiary == address(0)) continue; // Skip zero addresses

        if (_asset == address(0)) {
            (bool success,) = payable(beneficiary).call{value: amountPerBeneficiary}("");
            require(success, "transfer failed");
        } else {
            IERC20(_asset).safeTransfer(beneficiary, amountPerBeneficiary);
        }
    }
    // ...
}
```

## CodeHawks Format

## [M-1] Zero address handling vulnerabilities in beneficiary management can lead to permanent fund loss

## Summary

The `InheritanceManager` contract lacks proper zero address validation when managing beneficiaries. It allows zero addresses to be added as beneficiaries and uses `delete` on array elements which converts entries to the zero address without removing them. When inheritance is triggered, the contract attempts to distribute funds to all addresses in the array, including zero addresses, which can result in funds being permanently lost.

## Vulnerability Details

There are three key components to this vulnerability:

1. The `addBeneficiery` function doesn't validate against zero addresses:

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    // No zero address check
    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

2. The `removeBeneficiary` function uses `delete` which sets the array element to address(0) but keeps it in the array:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
    delete beneficiaries[indexToRemove]; // Sets to address(0) but doesn't remove the element
}
```

3. The `withdrawInheritedFunds` function attempts to send funds to all addresses in the array without checking for zero addresses:

```solidity
function withdrawInheritedFunds(address _asset) external {
    // ...
    uint256 divisor = beneficiaries.length;
    // ...
    for (uint256 i = 0; i < divisor; i++) {
        address payable beneficiary = payable(beneficiaries[i]);
        (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
        require(success, "something went wrong");
    }
    // ...
}
```

When inheritance occurs, the contract will try to distribute funds equally to all entries in the beneficiaries array. If the array contains zero addresses, either from direct addition or as a result of using `delete`, the contract will attempt to send funds to address(0). This either results in the funds being permanently lost or in a transaction failure that prevents any beneficiary from receiving their inheritance.

## Impact

This vulnerability can lead to several serious consequences:

1. **Permanent loss of funds**: If ETH is sent to address(0), it becomes permanently inaccessible
2. **Inheritance distribution failure**: Attempting to send tokens to address(0) may cause the entire distribution to fail
3. **Incorrect distribution calculations**: Zero addresses in the array are counted in the divisor, leading to each beneficiary receiving less than their fair share
4. **Confusion in beneficiary management**: The array length doesn't reflect the actual number of valid beneficiaries

The issue is rated as medium severity because:

- It can lead to permanent fund loss under specific conditions
- It requires particular actions (adding zero address or using the removeBeneficiary function)
- It fundamentally breaks the inheritance distribution mechanism

## Tools Used

Manual code review and Foundry testing

## Proof of Concept

1. Add the following test to `InheritanceManager.t.sol`

```solidity
function test_zeroAddressBeneficiaryFundLoss() public {
    address user2 = makeAddr("user2");

    vm.startPrank(owner);
    // Add a valid beneficiary
    im.addBeneficiery(user1);
    // Add the zero address as a beneficiary
    im.addBeneficiery(address(0));
    // Add another valid beneficiary
    im.addBeneficiery(user2);

    // Fund the contract
    vm.deal(address(im), 3 ether);
    vm.stopPrank();

    // Wait for inheritance timelock to expire
    vm.warp(block.timestamp + 91 days);

    // Trigger inheritance
    vm.prank(user1);
    im.inherit();

    // Try to withdraw funds - this will attempt to send 1 ETH to address(0)
    vm.prank(user1);
    // This may revert or burn 1 ETH depending on the environment
    try im.withdrawInheritedFunds(address(0)) {
        // If it succeeds, check that 1 ETH was sent to address(0) (effectively burned)
        assertEq(address(0).balance, 1 ether);
        assertEq(user1.balance, 1 ether);
        assertEq(user2.balance, 1 ether);
    } catch {
        // If it reverts, no one gets their funds
        assertEq(address(im).balance, 3 ether);
        assertEq(user1.balance, 0);
        assertEq(user2.balance, 0);
    }
}
```

2. Run the test

```bash
$ forge test --mt test_zeroAddressBeneficiaryFundLoss
```

## Recommendations

1. Add zero address validation in the `addBeneficiery` function:

```solidity
function addBeneficiery(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "InheritanceManager: zero address not allowed");
    beneficiaries.push(_beneficiary);
    _setDeadline();
}
```

2. Implement proper array element removal in `removeBeneficiary` using swap-and-pop:

```solidity
function removeBeneficiary(address _beneficiary) external onlyOwner {
    bool found = false;
    uint256 indexToRemove = 0;

    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] == _beneficiary) {
            indexToRemove = i;
            found = true;
            break;
        }
    }

    require(found, "InheritanceManager: beneficiary not found");

    // Swap with the last element and pop (actually removes the element)
    beneficiaries[indexToRemove] = beneficiaries[beneficiaries.length - 1];
    beneficiaries.pop();

    _setDeadline();
}
```

3. Add a check in `withdrawInheritedFunds` to skip zero addresses:

```solidity
function withdrawInheritedFunds(address _asset) external {
    // ...
    uint256 divisor = 0;
    // First count valid beneficiaries
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (beneficiaries[i] != address(0)) {
            divisor++;
        }
    }

    require(divisor > 0, "InheritanceManager: no valid beneficiaries");

    if (_asset == address(0)) {
        uint256 ethAmountAvailable = address(this).balance;
        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] != address(0)) {
                address payable beneficiary = payable(beneficiaries[i]);
                (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
                require(success, "transfer failed");
            }
        }
    } else {
        // Similar changes for token transfers
        // ...
    }
}
```
