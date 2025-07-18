/* I hereby attest to the truth of the following facts:
*
*  I have not discussed the solidity code in my program with anyone
*  other than my instructor or the teaching assistants assigned to this course.
*
*  I have not used solidity code obtained from another student, or
*  any other unauthorized source, whether modified or unmodified.
*
*  If any solidity code or documentation used in my program was
*  obtained from another source, it has been clearly noted with citations in the
*  comments of my program.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract SupplierContractHub {
    Supplier[] supplierList;
    address[] supplierAddresses;
    //RestaurantContracts[] restaurantContracts;

    struct RestaurantContracts{
        address contractAddress;
        string supplierName;
        address supplierAddress;
        string restaurantName;
    }

 	struct Stock{
        string ingredient;
        int qty;
        int price;
    }

    struct Discount{
        int percentage;
        int minimumQty;
    }
	
	struct Supplier{
        address supplierAddress;
        string name;
        string[] ingredientsList;
        Stock[] stockList;
		mapping (string => Stock[]) ingredients; //i might remove this
        int contractDuration;
        int terminationPenalty;
        Discount[] discounts;
        bool active;
    }

    //Light weight returnable type of Supplier used for viewing all supliers
    struct SupplierSummary {
        address supplierAddress;
        string name;
        string[] ingredientsList;
        int contractDuration;
        int terminationPenalty;
        bool active;
    }        

    mapping(address => Supplier) public suppliers;
    mapping(address => RestaurantContracts[]) public allContracts;

    modifier isNotSupplier(){
        require(suppliers[msg.sender].active == false, "You are already a supplier!");
        _;
    }

	function addSupplier(string memory _name, int _contractDuration, int _terminationPenalty) public payable isNotSupplier{
        Supplier storage newSupplier = suppliers[msg.sender];
        newSupplier.supplierAddress = msg.sender;
        newSupplier.name = _name;
        newSupplier.contractDuration = _contractDuration;
        newSupplier.terminationPenalty = _terminationPenalty;
        newSupplier.active = true;
        supplierAddresses.push(msg.sender);
    }

    function addStock(string memory _ingredient, int _qty, int _price) public {
        //Check if ingredient is already in added stock list of supplier, if so only add the _qty
        //else push to the array

        suppliers[msg.sender].stockList.push(Stock({ingredient: _ingredient, qty : _qty, price: _price}));
    }

    function reduceStock(string memory _ingredient, int _reduceQty) public {
        //Check if ingredient is in stock list of supplier, if so reduce the _reduceQty
        //else throw error
        //if _reduceQty is greater than qty throw error
        //else reduce the qty
        //if qty is 0 remove from stock list
    }


    function addDiscount() public {

    }

    function viewSuppliers() public view returns(SupplierSummary[] memory) {
        SupplierSummary[] memory summaries = new SupplierSummary[](supplierAddresses.length);
        
        //Loop through the supplier list and add the summary of each supplier to the summaries array
        for (uint i = 0; i < supplierAddresses.length; i++) {
            address suppAddress = supplierAddresses[i];
            Supplier storage supplier = suppliers[suppAddress];

            summaries[i] = SupplierSummary({
                supplierAddress: supplier.supplierAddress,
                name: supplier.name,
                ingredientsList: supplier.ingredientsList,
                contractDuration: supplier.contractDuration,
                terminationPenalty: supplier.terminationPenalty,
                active: supplier.active
            });
        }
        return summaries;
    }

    function selectSupplier(address _supplierAddress, string memory _restaurantName) external {
	    //create child contract when restaurant choose which supplier to have a deal with
        //Child contract will be the IngredientTracker contract
        //Child contract will be initialized with the supplier address and the restaurant address

        IngredientTracker ingredientTracker = new IngredientTracker(_supplierAddress, msg.sender, address(this));
        allContracts[msg.sender].push(RestaurantContracts({contractAddress: address(ingredientTracker), supplierName: suppliers[_supplierAddress].name, supplierAddress: _supplierAddress, restaurantName: _restaurantName}));
        //as of now the viewing of contracts is only for restaurant, add functionality for supplier to view theirs as well
    }

    function viewContracts() external view returns (RestaurantContracts[] memory){
        return allContracts[msg.sender];
    }

    function viewSupplierStock(address _supplierAddress) public view returns (Stock[] memory) {        
        return suppliers[_supplierAddress].stockList;
    }


    // i get prices given supplier. go thru their stockList to find ingredient then its price 
    function getPrice(address supplier, string memory ingredient) public view returns (uint) {
        Stock[] memory stockList = suppliers[supplier].stockList;
        for (uint i = 0; i < stockList.length; i++) {
            // u cannot compare strings in solidity lmao with just a == I HATE IT SO MUCH
            if (keccak256(bytes(stockList[i].ingredient)) == keccak256(bytes(ingredient))) {
                return uint(stockList[i].price);
            }
        }
        revert("Ingredient not found!");
    }
}


contract IngredientTracker {
    address restaurant;
    address supplier;
    address private parent;

    enum DeliveryStatus {InStorage, Finalized, Shipped, Arrived, Completed}
    enum IssueStatus { NoIssue, UnderInvestigation, FoundIssue, Verified, Rejected, Resolved }
    //Ingredient and its respective quantity
    struct Stock{
        string ingredient;
        uint qty; 
    }

    // added terminated bool for isNotTerminated modifier
    // NOTE: made date an uint
    struct Order {
        uint id;
        Stock[] ingredients;
        Stock[] damagedItems;
        uint date;
        uint discount;
        uint refundPrice; 
        uint finalPrice;
        DeliveryStatus deliveryStatus;
        IssueStatus issueStatus;
        bool terminated;
        string rejectionReason;
    }

    mapping(uint => Order) public orders;
    uint public orderCount;

    //restaurant initializes the contract
    constructor(address _supplier, address _restaurant, address _parent){
        restaurant = _restaurant;
        supplier = _supplier;
        parent = _parent;
        //Child contract will be initialized with the supplier's stock list,discounts, contract duration, termination penalty, active status, name, stock
    }


    //check if caller is restaurant
    modifier isRestaurant() {
        require(msg.sender == restaurant, "You are not the restaurant!");
        _;
    }

    //check if caller is supplier
    modifier isSupplier() {
        require(msg.sender == supplier, "You are not the authorized supplier!");
        _;
    }

    //check if order is shipped
    modifier isShipped(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Shipped, "Order has not been shipped!");
        _;
    }
    
    //check if order has arrived
    modifier hasArrived(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Arrived, "Order has not arrived!");
        _;
    }

    modifier isFinalized(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Finalized, "Order is not finalized by restaurant!");
        _;
    }

    modifier isUnderInvestigation(uint orderId) {
        require(orders[orderId].issueStatus == IssueStatus.UnderInvestigation, "Order has not arrived so it is not under investigation!");
        _;
    }

    modifier hasFoundIssue(uint orderId) {
        require(orders[orderId].issueStatus == IssueStatus.FoundIssue, "You have not reported an issue with this order!");
        _;
    }

    modifier hasNotFoundIssue(uint orderId) {
        require(orders[orderId].issueStatus != IssueStatus.FoundIssue, "An issue has been reported with this order!");
        _;
    }

    modifier isNotExpired(uint orderId) {
        require(block.timestamp <= orders[orderId].date, "Order has expired.");
        _;
    }
    
    modifier isNotTerminated(uint orderId) {
        require(!orders[orderId].terminated, "Order is terminated.");
    _;
    }

    //FOR TESTING PURPOSES ONLY
    function viewSupplierAddress() external view returns(address supplierAddress) {
        return supplier;
    }


    /* these functions change the status  of the order */

    //supplier changes order status to shipped
    function shipOrder(uint orderId) public isSupplier {
        orders[orderId].deliveryStatus = DeliveryStatus.Shipped;
    }
    
    //supplier changes shipped order status to arrived  
    function orderArrived(uint orderId) public isShipped(orderId) isSupplier {
        orders[orderId].deliveryStatus = DeliveryStatus.Arrived;
        orders[orderId].issueStatus = IssueStatus.UnderInvestigation;
    }

    //restaurant finalizes order, so no more updating
    function finalizeOrder(uint orderId) public isRestaurant {
        orders[orderId].deliveryStatus = DeliveryStatus.Finalized;
    }

    //restaurant changes shipped order status to complete  
    function orderCompleted(uint orderId) public hasArrived(orderId) isRestaurant hasNotFoundIssue(orderId) {
        orders[orderId].deliveryStatus = DeliveryStatus.Completed;
    }

    function viewOrder(uint orderId) public view returns (Order memory){
        return orders[orderId];
    }

    function checkDeliveryStatus(uint orderId) public view returns (DeliveryStatus){
        return orders[orderId].deliveryStatus;
    }    

    function orderNoIssue(uint orderId) public hasArrived(orderId) isRestaurant {
        orders[orderId].issueStatus = IssueStatus.NoIssue;
    }

    /* IMPORTANT FUNCTIONS*/


    //restaurant initiates empty order with supplier
    // TODO NICO - Add more under order details
    // removed isNotExpired and isNotTerminated modifier since it is making a new order, nothing to check yet
    function createOrder(uint _deliverydate) public isRestaurant  {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.deliveryStatus = DeliveryStatus.InStorage; 
        newOrder.date = block.timestamp + _deliverydate;
        newOrder.terminated = false;
    }

    //edited uriels og function 
    // Stock is an array, filled with dictionaries or a dictionary, just making sure ill research this
    // there should be functionality to update the stock count of the supplier, i think this is part of this
    function addIngredient(uint orderId, string memory _ingredient, uint _qty) isRestaurant public {
        orders[orderId].ingredients.push(Stock({ingredient: _ingredient, qty : _qty}));
    }

    //did same thing with this
    function getIngredientsList(uint orderId) public view returns (Stock[] memory){
        return orders[orderId].ingredients;
    }

    // can just -1 index the order array to return the order, make it as new one
    // increment orderCount since new order will be instantiated
    function copyLastOrder() public {
        require(orderCount > 0, "No previous order to copy!");
        
        // instantiate new order
        orderCount++;
        Order storage newOrder = orders[orderCount];
        
        newOrder.id = orderCount;
        newOrder.deliveryStatus = DeliveryStatus.InStorage;
        newOrder.issueStatus = IssueStatus.NoIssue;
        newOrder.date = orders[orderCount - 1].date;
        newOrder.terminated = false;

        // copying the ingredients
        for (uint i = 0; i < orders[orderCount - 1].ingredients.length; i++) {
        newOrder.ingredients.push(
            Stock({
                ingredient: orders[orderCount - 1].ingredients[i].ingredient,
                qty: orders[orderCount - 1].ingredients[i].qty
            })
        );
        }
    }

    //check if order has been checked out already, so this function will work on non checked out orders only
    // parameters are orderid, ingredients, quantity
    // will search in order array from the orderid, then will look thru the dictionary if there is ingredient
    // make sure to have a catch function if ingredient is not there, or supply is not enough
    function editOrder(uint orderId, string memory _ingredient, uint _qty) isRestaurant isNotExpired(orderId) isNotTerminated(orderId) public {
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Order already finalized!");

        bool isIngredientPresent = false;

        // u cannot compare strings in solidity lmao
        // https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity
        for (uint i = 0; i < orders[orderId].ingredients.length; i++) {
            if (
            keccak256(abi.encodePacked(orders[orderId].ingredients[i].ingredient)) ==
            keccak256(abi.encodePacked(_ingredient))
            ) {
                orders[orderId].ingredients[i].qty = _qty;
                isIngredientPresent = true;
                break;
            }
        }

        require(isIngredientPresent == true, "Ingredient not found in the order!");
    }

    // TO DO - NICO
    // calculate costs and pay to contract and change status to ORDERED
    // calculate probably from based on orders.finalprice???? not sure about this
    // NOTE NO REDUCESTOCK YET, if implemented put here
    function checkoutOrder(uint orderId) payable public isNotExpired(orderId) isNotTerminated(orderId) {
        Order storage currentOrder = orders[orderId];
        require(currentOrder.deliveryStatus == DeliveryStatus.InStorage, "Order already checked out or finalized.");

        uint totalCost = 0;

        for (uint i = 0; i < currentOrder.ingredients.length; i++) {
            string memory ingredientName = currentOrder.ingredients[i].ingredient;
            uint qtyOrdered = currentOrder.ingredients[i].qty;

            // calls parent for the price of ingredient
            uint pricePerUnit = SupplierContractHub(parent).getPrice(supplier, ingredientName);
            totalCost += pricePerUnit * qtyOrdered;
        }

        // sets the finalprice before all the verification on the side of supplier
        currentOrder.finalPrice = totalCost;

        // checks if sent money is enough
        require(msg.value >= totalCost, "Not enough money sent for the order!");
    }


    //supplier places details TODO
    function placeOrderDetails(uint orderId) public isSupplier isFinalized(orderId) {
        //place date
        //discount
        //final price etc
    }

    //TODO
    function updateIngredients() isRestaurant public {

    }

    // restaurant gives list of ingredient and their quantities that r broken
    function reportIssue(uint orderId, string[] memory ingredients, uint[] memory quantities) public isRestaurant hasArrived(orderId) isUnderInvestigation(orderId) {
        require(ingredients.length == quantities.length, "Length mismatch!");
        if(orders[orderId].issueStatus == IssueStatus.FoundIssue){
            revert("You can only report issue once!");
        }

        orders[orderId].issueStatus = IssueStatus.FoundIssue;

        for (uint i = 0; i < ingredients.length; i++) {
            orders[orderId].damagedItems.push(Stock({ingredient: ingredients[i], qty: quantities[i]}));
        }
    }


    //suppllier verifies the issue
    function verifyIssue(uint orderId, bool valid, string memory reason) public isSupplier hasFoundIssue(orderId) { 
        if (valid) {
            orders[orderId].issueStatus = IssueStatus.Verified;
        } else {
            orders[orderId].issueStatus = IssueStatus.Rejected;
            orders[orderId].rejectionReason = reason;
        }
    }

    //finds new final price. resolves the issue 
    function resolveIssue(uint orderId) public isSupplier {
        require(orders[orderId].issueStatus == IssueStatus.Verified, "Order issue has not been verified!");

        Stock[] memory items = orders[orderId].damagedItems;
        uint newDamagedPrice = 0;
        for (uint i = 0; i < items.length; i++) {
            uint price = SupplierContractHub(parent).getPrice(supplier, items[i].ingredient);
            newDamagedPrice += (items[i].qty * price) / 2;
        }

        orders[orderId].refundPrice = newDamagedPrice;
        orders[orderId].finalPrice -= orders[orderId].refundPrice;
        orders[orderId].issueStatus = IssueStatus.Resolved;

    }
    
}