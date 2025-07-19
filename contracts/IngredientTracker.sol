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

    struct RestaurantContracts{
        address contractAddress;
        string supplierName;
        address supplierAddress;
        string restaurantName;
    }

 	struct Stock{
        string ingredient;
        int qty;
        uint price;
    }

    struct Discount{
        uint percentage;
        uint minimumCost;
    }
	
	struct Supplier{
        address supplierAddress;
        string name;
        string[] ingredientsList;
        mapping (string => Stock) stockList;
        uint contractDuration;
        int terminationPenalty;
        Discount[] discounts;
        bool active;
    }

    struct SupplierSummary {
        address supplierAddress;
        string name;
        string[] ingredientsList;
        uint contractDuration;
        int terminationPenalty;
        bool active;
    }        

    mapping(address => Supplier) public suppliers; 
    mapping(address => RestaurantContracts[]) public allContracts;
    // to check if it is an authorized child contract
    mapping(address => bool) public isAuthorizedChild;

    modifier isNotSupplier(){
        require(suppliers[msg.sender].active == false, "You are already a supplier!");
        _;
    }

    modifier isSupplier(){
        require(suppliers[msg.sender].active == true, "You are not a supplier!");
        _;
    }

    modifier isAuthorized() {
        require(isAuthorizedChild[msg.sender], "Only authorized child contracts can call this function.");
    _;
    }

	function addSupplier(string memory _name, uint _contractDuration, int _terminationPenalty) external isNotSupplier{
        Supplier storage newSupplier = suppliers[msg.sender];
        newSupplier.supplierAddress = msg.sender;
        newSupplier.name = _name;
        newSupplier.contractDuration = _contractDuration;
        newSupplier.terminationPenalty = _terminationPenalty;
        newSupplier.active = true;
        supplierAddresses.push(msg.sender);
    }

    function addStock(string memory _ingredient, int _qty, uint _price) public isSupplier{
        suppliers[msg.sender].stockList[_ingredient].ingredient = _ingredient;
        suppliers[msg.sender].stockList[_ingredient].qty += _qty;
        suppliers[msg.sender].stockList[_ingredient].price = _price;
        
        //check if _ingredient is not in suppliers[msg.sender].ingredientsList, if so then push _ingredient to ingredientsList
        bool inList = false;
        string memory a = _ingredient;
        for (uint i = 0; i < suppliers[msg.sender].ingredientsList.length; i++){
            string memory b = suppliers[msg.sender].ingredientsList[i];
            if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))){
                inList = true;
                break;
            }
        }
        if (inList == false){
            suppliers[msg.sender].ingredientsList.push(_ingredient);
        }
    }
        
    //function for supplier to reduce stock of supplier
    function reduceStock(string memory _ingredient, int _reduceQty) external isSupplier{
        require(_reduceQty > 0, "You must reduce a positive amount of quantity!");
        require(_reduceQty <= suppliers[msg.sender].stockList[_ingredient].qty, "You reduce more than the current quantity!");
        suppliers[msg.sender].stockList[_ingredient].qty -= _reduceQty;
    }

    //function to reduce the quantity on the stock Sold
    function stockSold(string memory _ingredient, int _reduceQty) external {
        suppliers[msg.sender].stockList[_ingredient].qty -= _reduceQty;
    }

    function addDiscount(uint _discount, uint _minimumCost) external isSupplier {
        suppliers[msg.sender].discounts.push(Discount({percentage: _discount, minimumCost: _minimumCost}));
    }

    function clearDiscounts() external isSupplier {
        delete suppliers[msg.sender].discounts;
    }

    function viewDiscount(address _supplierAddress) public view returns (Discount[] memory){
        return suppliers[_supplierAddress].discounts;
    }

    function viewSuppliers() public view returns(SupplierSummary[] memory) {
        SupplierSummary[] memory summaries = new SupplierSummary[](supplierAddresses.length);
        
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

    function selectSupplier(address _supplierAddress, string memory _restaurantName) external isNotSupplier {
        IngredientTracker ingredientTracker = new IngredientTracker(_supplierAddress, msg.sender, address(this), suppliers[_supplierAddress].contractDuration);
        allContracts[msg.sender].push(RestaurantContracts({contractAddress: address(ingredientTracker), supplierName: suppliers[_supplierAddress].name, supplierAddress: _supplierAddress, restaurantName: _restaurantName}));
        //as of now the viewing of contracts is only for restaurant, add functionality for supplier to view theirs as well

        // make the new child contract a authorized child
        isAuthorizedChild[address(ingredientTracker)] = true;
    }

    function viewContracts() external view returns (RestaurantContracts[] memory){
        return allContracts[msg.sender];
    }

    function viewSupplierStock(address _supplierAddress) public view returns (Stock[] memory) {
        uint length = suppliers[_supplierAddress].ingredientsList.length;
        Stock[] memory stockSummary = new Stock[](length);
        for (uint i = 0; i < length; i++){
            string memory ingredient = suppliers[_supplierAddress].ingredientsList[i];

            stockSummary[i] = Stock({
                ingredient: suppliers[_supplierAddress].stockList[ingredient].ingredient,
                qty: suppliers[_supplierAddress].stockList[ingredient].qty,
                price: suppliers[_supplierAddress].stockList[ingredient].price
            });
        }
        return stockSummary;
    }

    function getPrice(address _supplier, string memory _ingredient) public view returns (uint) {
        return suppliers[_supplier].stockList[_ingredient].price;
    }

    function getIngredientQty(address _supplier, string memory _ingredient) public view returns (int) {
        return suppliers[_supplier].stockList[_ingredient].qty;
    }
}


contract IngredientTracker {
    address restaurant;
    address supplier;
    address private parent;
    uint expiryDate;
    Discount[] discounts;
    bool terminated; 
    
    struct Discount{
        uint percentage;
        uint minimumCost;
    }    

    enum DeliveryStatus {InStorage, Finalized, Shipped, Arrived, Completed}
    enum IssueStatus { NoIssue, UnderInvestigation, FoundIssue, Verified, Rejected, Resolved }

    struct Item{
        string ingredient;
        uint qty; 
    }

    struct Order {
        uint id;
        Item[] ingredients;
        Item[] damagedItems;
        uint date;
        uint discount;
        uint refundPrice; 
        uint finalPrice;
        DeliveryStatus deliveryStatus;
        IssueStatus issueStatus;
        string rejectionReason;
    }

    mapping(uint => Order) public orders;
    uint public orderCount;

    constructor(address _supplier, address _restaurant, address _parent, uint _expiryDate){
        restaurant = _restaurant;
        supplier = _supplier;
        parent = _parent;
        expiryDate = block.timestamp + _expiryDate;
        fetchDiscounts();
        terminated = false; 
        //Child contract will be initialized with the supplier's stock list,discounts, contract duration, termination penalty, active status, name, stock
    }

    modifier isRestaurant() {
        require(msg.sender == restaurant, "You are not the restaurant!");
        _;
    }

    modifier isSupplier() {
        require(msg.sender == supplier, "You are not the authorized supplier!");
        _;
    }

    modifier isShipped(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Shipped, "Order has not been shipped!");
        _;
    }
    
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

    modifier isNotExpired() {
        require(block.timestamp <= expiryDate, "Contract has expired.");
        _;
    }
    
    modifier isNotTerminated() {
        require(terminated == false, "Contract is terminated.");
    _;
    }

    //FOR TESTING PURPOSES ONLY
    function viewSupplierAddress() external view returns(address supplierAddress) {
        return supplier;
    }

    function fetchDiscounts() private {
        SupplierContractHub.Discount[] memory supplierDiscounts = SupplierContractHub(parent).viewDiscount(supplier);
        delete discounts;

        for (uint i = 0; i < supplierDiscounts.length; i++) {
            discounts.push(Discount({ percentage: supplierDiscounts[i].percentage, minimumCost: supplierDiscounts[i].minimumCost }));
        }
    }


    /* these functions change the status  of the order */

    function shipOrder(uint orderId) public isSupplier isFinalized(orderId) {
        orders[orderId].deliveryStatus = DeliveryStatus.Shipped;
    }
    
    function orderArrived(uint orderId) public isShipped(orderId) isSupplier {
        orders[orderId].deliveryStatus = DeliveryStatus.Arrived;
        orders[orderId].issueStatus = IssueStatus.UnderInvestigation;
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

    function createOrder(uint _deliverydate) public isRestaurant  {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.deliveryStatus = DeliveryStatus.InStorage; 
        newOrder.date = block.timestamp + _deliverydate;
    }

    function addIngredient(uint orderId, string memory _ingredient, uint _qty) isRestaurant public {
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Your order has already been paid and processed.");
        orders[orderId].ingredients.push(Item({ingredient: _ingredient, qty : _qty}));
    }

    function getIngredientsList(uint orderId) public view returns (Item[] memory){
        return orders[orderId].ingredients;
    }

    function copyLastOrder(uint date) public {
        require(orderCount > 0, "No previous order to copy!");
  
        orderCount++;
        Order storage newOrder = orders[orderCount];
        
        newOrder.id = orderCount;
        newOrder.deliveryStatus = DeliveryStatus.InStorage;
        newOrder.issueStatus = IssueStatus.NoIssue;
        newOrder.date = block.timestamp + date;

        // copying the ingredients
        for (uint i = 0; i < orders[orderCount - 1].ingredients.length; i++) {
        newOrder.ingredients.push(
            Item({
                ingredient: orders[orderCount - 1].ingredients[i].ingredient,
                qty: orders[orderCount - 1].ingredients[i].qty
            })
        );
        }
    }

    function editOrder(uint orderId, string memory _ingredient, uint _qty) isRestaurant isNotExpired() isNotTerminated() public {
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Order already finalized!");
        bool isIngredientPresent = false;

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

    function checkoutOrder(uint orderId) payable public isNotExpired() isNotTerminated() isRestaurant {
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

        //recalculate with discount
        uint highestDiscount = 0;
        for (uint i = 0; i < discounts.length; i++) {
            if (totalCost >= discounts[i].minimumCost) {
                if (discounts[i].percentage > highestDiscount){
                    highestDiscount = discounts[i].percentage;
                }
            }
        }
        totalCost = totalCost * ((100 - highestDiscount)/ 100);
        
        // sets the finalprice before all the verification on the side of supplier
        currentOrder.finalPrice = totalCost;        

        // checks if sent money is enough
        require(msg.value >= totalCost, "Not enough money sent for the order!");

        //reduce stock 
        for (uint i = 0; i < currentOrder.ingredients.length; i++) {
            string memory ingredientName = currentOrder.ingredients[i].ingredient;
            uint qtyOrdered = currentOrder.ingredients[i].qty;
            SupplierContractHub(parent).stockSold(ingredientName, int(qtyOrdered));
        }

        currentOrder.deliveryStatus = DeliveryStatus.Finalized;
    }

    receive() external payable {}

    //restaurant adds to damagedItems a damaged ingredient and quantity
    function reportIssue(uint orderId, string memory _ingredient, uint _qty) isRestaurant isUnderInvestigation(orderId) public {
        orders[orderId].damagedItems.push(Item({ingredient: _ingredient, qty : _qty}));
    }

    //submits it to supplier
    function submitIssue(uint orderId) public {
        if(orders[orderId].issueStatus == IssueStatus.FoundIssue){
            revert("You can only report issue once!");
        }
        if (orders[orderId].damagedItems.length <= 0) {
            revert("You have not reported any issue with the ingredients!");
        }
        orders[orderId].issueStatus = IssueStatus.FoundIssue;
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

        Item[] memory items = orders[orderId].damagedItems;
        uint newDamagedPrice = 0;
        for (uint i = 0; i < items.length; i++) {
            uint price = SupplierContractHub(parent).getPrice(supplier, items[i].ingredient);
            newDamagedPrice += (items[i].qty * price) / 2;
        }

        orders[orderId].refundPrice = newDamagedPrice;
        orders[orderId].finalPrice -= orders[orderId].refundPrice;
        orders[orderId].issueStatus = IssueStatus.Resolved;
    }
    
    function terminateContract() public {
        parent = address(0);
        supplier = address(0);
        restaurant = address(0);
        terminated = true;
    }

    function settlePayment(uint orderId) public isRestaurant hasArrived(orderId) {
        require(orders[orderId].issueStatus == IssueStatus.NoIssue || orders[orderId].issueStatus == IssueStatus.Resolved || orders[orderId].issueStatus == IssueStatus.Rejected, "Your order is still under quality checking.");
        payable(supplier).transfer(orders[orderId].finalPrice);
        payable(restaurant).transfer(orders[orderId].refundPrice);

        orders[orderId].deliveryStatus = DeliveryStatus.Completed;

    }

    function renewContract(uint newDate) public isRestaurant {
        expiryDate = newDate;
    }

    function cancelOrder(uint orderId) public isRestaurant {
        require(orderId > 0 && orderId <= orderCount, "Invalid order ID");
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Order has already been processed.");

        if (orderId != orderCount) {
            orders[orderId] = orders[orderCount];
            orders[orderId].id = orderId; 
        }

        delete orders[orderCount];
        orderCount--;
    }


    //Update code: Kino 10:54AM 7/19/2025. 501 lines of code

}