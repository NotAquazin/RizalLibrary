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

        IngredientTracker ingredientTracker = new IngredientTracker(_supplierAddress, msg.sender);
        allContracts[msg.sender].push(RestaurantContracts({contractAddress: address(ingredientTracker), supplierName: suppliers[_supplierAddress].name, supplierAddress: _supplierAddress, restaurantName: _restaurantName}));
        //as of now the viewing of contracts is only for restaurant, add functionality for supplier to view theirs as well
    }

    function viewContracts() external view returns (RestaurantContracts[] memory){
        return allContracts[msg.sender];
    }

    function viewSupplierStock(address _supplierAddress) public view returns (Stock[] memory) {        
        return suppliers[_supplierAddress].stockList;
    }
}


contract IngredientTracker {
    address restaurant;
    address supplier;

    enum STATUS {InStorage, Finalized, Shipped, Arrived, Investigation, Completed}

    //Ingredient and its respective quantity
    struct Stock{
        string ingredient;
        uint qty; 
    }


    // ALL THESE ARE TRANSFERRED TO ORDER STRUCT
    // struct Details{
    //     string date;
    //     uint discount;
    //     uint refundPrice; 
    //     uint finalPrice;
    //     STATUS status; 
    // }


    // i made this a struct because a restaurant can have multiple orders -mady
    // added terminated bool for isNotTerminated modifier
    // NOTE: made date an uint
    struct Order {
        uint id;
        address supplier;
        Stock[] ingredients;
        //Details details;
        uint date;
        uint discount;
        uint refundPrice; 
        uint finalPrice;
        STATUS status;
        bool terminated;
    }

    mapping(uint => Order) public orders;
    uint public orderCount;

    //restaurant initializes the contract
    constructor(address _supplier, address _restaurant){
        restaurant = _restaurant;
        supplier = _supplier;
        //Child contract will be initialized with the supplier's stock list,discounts, contract duration, termination penalty, active status, name, stock
    }


    //check if caller is restaurant
    modifier isRestaurant() {
        require(msg.sender == restaurant, "You are not the restaurant!");
        _;
    }

    //check if caller is supplier
    modifier isSupplier(uint orderId) {
        require(msg.sender == orders[orderId].supplier, "You are not the authorized supplier!");
        _;
    }

    //check if order is shipped
    modifier isShipped(uint orderId) {
        require(orders[orderId].status == STATUS.Shipped, "Order has not been shipped!");
        _;
    }
    
    //check if order has arrived
    modifier hasArrived(uint orderId) {
        require(orders[orderId].status == STATUS.Arrived, "Order has not arrived!");
        _;
    }

    modifier isFinalized(uint orderId) {
        require(orders[orderId].status == STATUS.Finalized, "Order is not finalized by restaurant!");
        _;
    }

    modifier isUnderInvestigation(uint orderId) {
        require(orders[orderId].status == STATUS.Investigation, "You have not reported an issue with this order!");
        _;
    }

    modifier notUnderInvestigation(uint orderId) {
        require(orders[orderId].status != STATUS.Investigation, "An issue has been reported with this order!");
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
    function shipOrder(uint orderId) public isSupplier(orderId) {
        orders[orderId].status = STATUS.Shipped;
    }
    
    //supplier changes shipped order status to arrived  
    function orderArrived(uint orderId) public isShipped(orderId) isSupplier(orderId) {
        orders[orderId].status = STATUS.Arrived;
    }

    //restaurant finalizes order, so no more updating
    function finalizeOrder(uint orderId) public isRestaurant {
        orders[orderId].status = STATUS.Finalized;
    }

    //restaurant changes shipped order status to complete  
    function orderCompleted(uint orderId) public hasArrived(orderId) isRestaurant notUnderInvestigation(orderId) {
        orders[orderId].status = STATUS.Completed;
    }

    function viewOrder(uint orderId) public view returns (Order memory){
        return orders[orderId];
    }

    function checkStatus(uint orderId) public view returns (STATUS){
        return orders[orderId].status;
    }    


    /* IMPORTANT FUNCTIONS*/


    //restaurant initiates empty order with supplier
    // TODO NICO - Add more under order details
    // removed isNotExpired and isNotTerminated modifier since it is making a new order, nothing to check yet
    function createOrder(address _supplier, uint _deliverydate) public isRestaurant  {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.supplier = _supplier;
        newOrder.status = STATUS.InStorage; 
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
        newOrder.supplier = orders[orderCount - 1].supplier;
        newOrder.status = STATUS.InStorage;
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
    function editOrder(uint orderId, string memory _ingredient, uint _qty) isRestaurant isNotExpired() isNotTerminated public {
        require(orders[orderId].status == STATUS.InStorage, "Order already finalized!");

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
    function checkoutOrder() public {

    }


    //supplier places details TODO
    function placeOrderDetails(uint orderId) public isSupplier(orderId) isFinalized(orderId) {
        //place date
        //discount
        //final price etc
    }

    //TODO
    function updateIngredients() isRestaurant public {

    }

    //TODO 
    function reportIssue(uint orderId) public isRestaurant hasArrived(orderId) {
        //smthg idk 
        orders[orderId].status = STATUS.Investigation;
    }

    //TODO 
    function resolveIssue(uint orderId) public isUnderInvestigation(orderId) isSupplier(orderId) {
        //refund magic blah blah 
        orders[orderId].status = STATUS.Completed;
    }

    //restaurant pays order 
    function payOrder(uint orderId) external payable isRestaurant isFinalized(orderId) {
        //check if pay is equal or greater to the final price 
    }
    
}