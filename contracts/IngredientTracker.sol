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

contract IngredientTracker {
    address restaurant;
    address supplier;

    enum STATUS {InStorage, Finalized, Shipped, Arrived, Completed}

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

    //restaurant initiates empty order with supplier
    function createOrder(address _supplier) public isRestaurant {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.supplier = _supplier;
        newOrder.details.status = STATUS.InStorage; 
    }

    //supplier changes order status to shipped
    function shipOrder(uint orderId) public isSupplier(orderId) {
        orders[orderId].details.status = STATUS.Shipped;
    }
    
    //restaurant changes shipped order status to arrived  
    function orderArrived(uint orderId) public isShipped(orderId) isRestaurant {
        orders[orderId].details.status = STATUS.Arrived;
    }
    
    //edited uriels og function 
    function addIngredient(uint orderId, string memory _ingredient, uint _qty) isRestaurant public{
        orders[orderId].ingredients.push(Stock({ingredient: _ingredient, qty : _qty}));
    }

    //did same thing with this
    function getIngredientsList(uint orderId) public view returns (Stock[] memory){
        return orders[orderId].ingredients;
    }

    //restaurant finalizes order, so no more updating
    function finalizeOrder(uint orderId) public isRestaurant {
        orders[orderId].details.status = STATUS.Finalized;
    }

    //supplier places details TODO
    function placeOrderDetails(uint orderId) public isSupplier(orderId) isFinalized(orderId) {

    }

    //TODO
    function updateIngredients() isRestaurant public {

    }

    //TODO 
    function reportIssue(uint orderId) public isRestaurant hasArrived(orderId) {

    }

    //restaurant changes shipped order status to complete  
    function orderCompleted(uint orderId) public hasArrived(orderId) isRestaurant {
        orders[orderId].details.status = STATUS.Completed;
    }
    
}