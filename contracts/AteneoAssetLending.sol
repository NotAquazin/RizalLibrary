// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/// @notice Structure representing an asset available for lending
struct Asset {
    address owner;
    string name;
    uint rental_fee;
    bool borrowed;
    address currentContract;
}

contract AteneoLendingContract {

    // TO ADD: Set the penalty fee for returning an asset late
    // TO ADD: Set the security deposit for all borrowers 

    mapping(address => bool) public flags; // Mapping of flagged users
    mapping(address => bool) private borrowers; // Mapping of borrowers and borrowing status
    Asset[] public listedAssets; // Array of assets for borrowing

    /// @notice Modifier that checks if user is flagged
    modifier flagged() {
        // TO ADD: Modifier to check if user is flagged, else revert with an error message saying that user is not flagged
        _;
    }

    /// @notice Modifier that checks if user is not flagged
    modifier notFlagged() {
        // TO ADD: Modifier to check if user is not flagged, else revert with an error message for paying penalty
        _;
    }

    /// @notice Modifier that checks if user is not flagged
    modifier notBorrowing() {
        // TO ADD: Modifier to check if user is not currently borrowing an asset
        _;
    }

    /// @notice List a new asset for lending
    /// @param _name The name of the asset
    /// @param _rental_fee The rental fee for borrowing the asset
    function listItem(string memory _name, uint _rental_fee) external {
        // TO ADD: Add asset to the list of available assets
    }

    /// @notice Borrow an asset by ID, paying rental and deposit fees
    /// @param _itemId The index of the asset in the list
    function borrow(uint _itemId) external payable notBorrowing notFlagged {
        // TO ADD: Check if _itemId is valid
        // TO ADD: Check if asset is already borrowed
        // TO ADD: Check if the payment is correct

        // TO ADD: Handle borrowing action, transfer deposit and rental fees, and update borrower and item status
    }

    /// @notice Mark an asset as returned (can only be called by the AssetContract)
    /// @param _itemId The index of the asset in the list
    function markReturned(uint _itemId, address _borrower) external {
        // TO ADD: Validate if caller is AssetContract
        // TO ADD: Validate if asset is borrowed

        // TO ADD: Update borrower and item status
    }

    /// @notice Flag a borrower who returned an asset late (can only be called by the AssetContract)
    /// @param _borrower The address of the borrower to be flagged
    /// @param _itemId The index of the borrowed asset
    function flag(address _borrower, uint _itemId) external {
        // TO ADD: Validate _itemId
        // TO ADD: Validate if caller is AssetContract
        // TO ADD: Update borrower status
    }

    /// @notice Pay the penalty fee to remove the flagged status
    function payPenalty() external payable flagged {
        // TO ADD: Check penalty payment amount and update borrower status
    }

    /// @notice Retrieve the full list of listed assets
    /// @return An array of all listed assets
    function getListedAssets() public view returns (Asset[] memory) {
        // TO ADD: Return the array of listed assets
    }
}

contract AssetContract {

    address private parent;
    address public owner;
    address public borrower;
    uint public itemId;
    uint public deadline;
    bool public returned;
    uint private duration = 30 seconds; // Set to 30 seconds only for testing purposes

    /// @notice Allow this contract to receive ether
    // TO ADD: fallback function to receive Ether transfers

    /// @notice Constructor sets initial state and deadline
    /// @param _parent The address of the AteneoLendingContract
    /// @param _owner The original owner of the asset
    /// @param _borrower The borrower of the asset
    /// @param _itemId The index of the borrowed asset
    constructor(address _parent, address _owner, address _borrower, uint _itemId) {
        // TO ADD: Constructor function statements
    }

    /// @notice Called by borrower to return the item, returns the deposit fee, and triggers penalty if overdue
    function returnItem() external {
        // TO ADD: Verify the borrower
        // TO ADD: Verify if the asset has already been returned
        
        // TO ADD: Handle return actions, update the return status, check return timestamp, and handle penalties if overdue
    }
}