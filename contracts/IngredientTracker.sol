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
        string name;
		Stock[] ingredients;
        int contractDuration;
        int terminationPenalty;
        Discount[] discounts;
        bool active;
    }

    mapping(address => Supplier) public suppliers;

	function addSupplier(
        address _supplierAddress,
        string memory _name,
        int _contractDuration, 
        int _terminationPenalty
        ) public payable {
        //add supplier to mapping
        Supplier storage newSupplier = suppliers[msg.sender];
        newSupplier.active = true;
    }

    function viewSuppliers() public view returns(Supplier[] memory) {

    }

    function selectSupplier() public{
	    //create child contract
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

    //The details of the contract
    struct Details{
        string date;
        uint discount;
        uint refundPrice; 
        uint finalPrice;
        STATUS status; 
    }

    // i made this a struct because a restaurant can have multiple orders -mady
    struct Order {
        uint id;
        address supplier;
        Stock[] ingredients;
        Details details;
    }

    mapping(uint => Order) public orders;
    uint public orderCount;

    //restaurant initializes the contract
    constructor(){
        restaurant = msg.sender;
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
        require(orders[orderId].details.status == STATUS.Shipped, "Order has not been shipped!");
        _;
    }
    
    //check if order has arrived
    modifier hasArrived(uint orderId) {
        require(orders[orderId].details.status == STATUS.Arrived, "Order has not arrived!");
        _;
    }

    modifier isFinalized(uint orderId) {
        require(orders[orderId].details.status == STATUS.Finalized, "Order is not finalized by restaurant!");
        _;
    }

    modifier isUnderInvestigation(uint orderId) {
        require(orders[orderId].details.status == STATUS.Investigation, "You have not reported an issue with this order!");
        _;
    }

    modifier notUnderInvestigation(uint orderId) {
        require(orders[orderId].details.status != STATUS.Investigation, "An issue has been reported with this order!");
        _;
    }


    /* these functions change the status  of the order */

    //supplier changes order status to shipped
    function shipOrder(uint orderId) public isSupplier(orderId) {
        orders[orderId].details.status = STATUS.Shipped;
    }
    
    //restaurant changes shipped order status to arrived  
    function orderArrived(uint orderId) public isShipped(orderId) isRestaurant {
        orders[orderId].details.status = STATUS.Arrived;
    }

    //restaurant finalizes order, so no more updating
    function finalizeOrder(uint orderId) public isRestaurant {
        orders[orderId].details.status = STATUS.Finalized;
    }

    //restaurant changes shipped order status to complete  
    function orderCompleted(uint orderId) public hasArrived(orderId) isRestaurant notUnderInvestigation(orderId) {
        orders[orderId].details.status = STATUS.Completed;
    }


    /* IMPORTANT FUNCTIONS*/


    //restaurant initiates empty order with supplier
    function createOrder(address _supplier) public isRestaurant {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.supplier = _supplier;
        newOrder.details.status = STATUS.InStorage; 
    }

    //edited uriels og function 
    function addIngredient(uint orderId, string memory _ingredient, uint _qty) isRestaurant public{
        orders[orderId].ingredients.push(Stock({ingredient: _ingredient, qty : _qty}));
    }

    //did same thing with this
    function getIngredientsList(uint orderId) public view returns (Stock[] memory){
        return orders[orderId].ingredients;
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
        orders[orderId].details.status = STATUS.Investigation;
    }

    //TODO 
    function resolveIssue(uint orderId) public isUnderInvestigation(orderId) isSupplier(orderId) {
        //refund magic blah blah 
        orders[orderId].details.status = STATUS.Completed;
    }

    //restaurant pays order 
    function payOrder(uint orderId) external payable isRestaurant isFinalized(orderId) {
        //check if pay is equal or greater to the final price 
    }
    
}