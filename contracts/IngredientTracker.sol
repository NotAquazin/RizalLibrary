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

    /// @notice RestaurantContracts struct that contains the details of a restaurant's contract.
    struct RestaurantContracts{
        address contractAddress;
        string supplierName;
        address supplierAddress;
        string restaurantName;
    }

    /// @notice Stock struct contains the details of an ingredients' stocks: ingredient name, quantity, and unit price.
 	struct Stock{
        string ingredient;
        int qty;
        uint price;
    }

    /// @notice Discount struct is the percentage discount based on the minimum total cost of an order.
    struct Discount{
        uint percentage;
        uint minimumCost;
    }

    /// @notice Supplier struct holds all the details of a supplier with their stocks and .
	struct Supplier{
        address supplierAddress;
        string name;
        string[] ingredientsList;
        mapping (string => Stock) stockList;
        uint contractDuration;
        uint terminationPenalty;
        Discount[] discounts;
        bool active;
    }

    /// @notice light weight struct that allows for view function to return supplier data.
    struct SupplierSummary {
        address supplierAddress;
        string name;
        string[] ingredientsList;
        uint contractDuration;
        uint terminationPenalty;
        bool active;
    }        

    mapping(address => Supplier) public suppliers; 
    mapping(address => RestaurantContracts[]) public allContracts;
    mapping(address => bool) public isAuthorizedChild;

    /// @notice Checks if user is not a supplier.
    modifier isNotSupplier(){
        require(suppliers[msg.sender].active == false, "You are already a supplier!");
        _;
    }

    /// @notice Checks if user is the supplier.
    modifier isSupplier(){
        require(suppliers[msg.sender].active == true, "You are not a supplier!");
        _;
    }

    /// @notice Checks valid child contract calls a function.
    /// @dev this modifer is used in stockSold function to make sure only child contract calls it.
    modifier isAuthorized() {
        require(isAuthorizedChild[msg.sender], "Only authorized child contracts can call this function.");
    _;
    }

    /// @notice Adds a supplier to the list of suppliers with its details.
    /// @param _name is the name of the supplier
    /// @param _contractDuration is the length of a contracts validity
    /// @param _terminationPenalty is the penalty fee for terminating the contract
    /// @dev supplier address is added to the list of supplier addresses
	function addSupplier(string memory _name, uint _contractDuration, uint _terminationPenalty) external isNotSupplier{
        Supplier storage newSupplier = suppliers[msg.sender];
        newSupplier.supplierAddress = msg.sender;
        newSupplier.name = _name;
        newSupplier.contractDuration = _contractDuration;
        newSupplier.terminationPenalty = _terminationPenalty;
        newSupplier.active = true;
        supplierAddresses.push(msg.sender);
    }
    
    /// @notice Adds ingredient stock details to the list of stocks of a supplier.
    /// @param _ingredient the ingredient name to be added.
    /// @param _qty the quantity of an ingredient to be added.
    /// @param _price the unit price of an ingredient.
    /// @dev checks if ingredient is already part of the listed stocks, if not add it to do the list of ingredients.
    function addStock(string memory _ingredient, int _qty, uint _price) public isSupplier{
        suppliers[msg.sender].stockList[_ingredient].ingredient = _ingredient;
        suppliers[msg.sender].stockList[_ingredient].qty += _qty;
        suppliers[msg.sender].stockList[_ingredient].price = _price;
        
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
        
    /// @notice Reduces the quantity of stocks of an ingredient.
    /// @param _ingredient the ingredient to be reduced in quantity.
    /// @param _reduceQty the number to reduce in the ingredient's quantity.
    /// @dev can only be called by the supplier on their own stock
    function reduceStock(string memory _ingredient, int _reduceQty) external isSupplier{
        require(_reduceQty > 0, "You must reduce a positive amount of quantity!");
        require(_reduceQty <= suppliers[msg.sender].stockList[_ingredient].qty, "You reduce more than the current quantity!");
        suppliers[msg.sender].stockList[_ingredient].qty -= _reduceQty;
    }

    /// @notice Reduces the quantity of stocks of an ingredient.
    /// @param _ingredient the ingredient to be reduced in quantity.
    /// @param _reduceQty the number to reduce in the ingredient's quantity.
    /// @dev can only be called by the a child contract when order is made.
    function stockSold(string memory _ingredient, int _reduceQty) external isAuthorized {
        suppliers[msg.sender].stockList[_ingredient].qty -= _reduceQty;
    }

    /// @notice Adds a discount to the list of discounts of a supplier
    /// @param _discount the whole number percentage of the discount
    /// @param _minimumCost the minimum total cost to avail the discount
    function addDiscount(uint _discount, uint _minimumCost) external isSupplier {
        suppliers[msg.sender].discounts.push(Discount({percentage: _discount, minimumCost: _minimumCost}));
    }

    /// @notice Clears the list of discounts of a supplier
    function clearDiscounts() external isSupplier {
        delete suppliers[msg.sender].discounts;
    }

    /// @notice Views the list of discounts of a certain supplier.
    /// @param _supplierAddress the address of the supplier of which discounts' are to be viewed.
    /// @return Discount array of Discount structs
    function viewDiscount(address _supplierAddress) public view returns (Discount[] memory){
        return suppliers[_supplierAddress].discounts;
    }

    /// @notice View the list of suppliers with their basic details
    /// @return summaries an arry of SupplierSummary structs
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

    /// @notice selects the supplier that a restaurant will want to have a contract with.
    /// @param _supplierAddress the address of the selected supplier.
    /// @param _restaurantName the name of the restaurant who selects the supplier.
    /// @dev Adds the contract address to the list of authorized child contracts.
    function selectSupplier(address _supplierAddress, string memory _restaurantName) external isNotSupplier {
        IngredientTracker ingredientTracker = new IngredientTracker(_supplierAddress, msg.sender, address(this), suppliers[_supplierAddress].contractDuration);
        allContracts[msg.sender].push(RestaurantContracts({contractAddress: address(ingredientTracker), supplierName: suppliers[_supplierAddress].name, supplierAddress: _supplierAddress, restaurantName: _restaurantName}));
        isAuthorizedChild[address(ingredientTracker)] = true;
    }

    /// @notice Views the list of contracts of a restaurant.
    /// @return RestaurantContracts an array of RestaurantContracts structs.
    function viewContracts() external view returns (RestaurantContracts[] memory){
        return allContracts[msg.sender];
    }

    /// @notice Views the stock details of a supplier such as the ingredients, their quantities, and unit pricings.
    /// @param _supplierAddress the address of the supplier.
    /// @return stockSummary an array of Stock structs.
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

    /// @notice retrieves the price of an ingredient of its respective supplier.
    /// @param _supplier the address of the supplier
    /// @param _ingredient the ingredient of which's price to be retrieved.
    /// @return uint price of the ingredient.
    function getPrice(address _supplier, string memory _ingredient) public view returns (uint) {
        return suppliers[_supplier].stockList[_ingredient].price;
    }

    /// @notice retrives the quantity of a certain ingredient from the respective supplier.
    /// @param _supplier the address of the supplier.
    /// @param _ingredient the ingredient of which's quantity is to be retrieved.
    /// @return qty of the ingredient in stock.
    function getIngredientQty(address _supplier, string memory _ingredient) public view returns (int) {
        return suppliers[_supplier].stockList[_ingredient].qty;
    }


    /// @notice Used in returning the supplier's stock list
    /// @dev This is used in addIngredient() function in the child contract
    /// @param _supplier The address of the supplier
    function getSupplierIngredientsList(address _supplier) external view returns (string[] memory) {
       return suppliers[_supplier].ingredientsList;
    }

    /// @notice Used to get the details of a specific ingredient
    /// @dev This is used in addIngredient() function in the child contract
    /// @param _supplier The address of the supplier
    /// @param _ingredient The ingredient that needs to be searched
    function getIngredientStockDetails(address _supplier, string memory _ingredient) external view returns (string memory, int, uint) {
        Stock memory s = suppliers[_supplier].stockList[_ingredient];
        return (s.ingredient, s.qty, s.price);
    }

    /// @notice Retrieves the termination penalty amount of a suppliers' contracts.
    /// @param _supplier the address of the supplier
    /// @return penalty the uint of how much the termination penalty of a supplier's associated contracts are.
    function getSupplierPenalty(address _supplier) public view returns (uint penalty) {
        return suppliers[_supplier].terminationPenalty;
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
    }

    ///@notice Checks if the user is the restaurant
    modifier isRestaurant() {
        require(msg.sender == restaurant, "You are not the restaurant!");
        _;
    }

    ///@notice Checks if the user is the supplier
    modifier isSupplier() {
        require(msg.sender == supplier, "You are not the authorized supplier!");
        _;
    }
    
    ///@notice Checks if the status of the delivery is shipped
    ///@param orderId Specifies the order ID 
    modifier isShipped(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Shipped, "Order has not been shipped!");
        _;
    }

    ///@notice Checks if the status of the delivery has arrived
    ///@param orderId Specifies the order ID 
    modifier hasArrived(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Arrived, "Order has not arrived!");
        _;
    }

    ///@notice Checks if the order is finalized
    ///@param orderId Specifies the order ID 
    modifier isFinalized(uint orderId) {
        require(orders[orderId].deliveryStatus == DeliveryStatus.Finalized, "Order is not finalized by restaurant!");
        _;
    }

    
    ///@notice Checks if the order is under investigation
    ///@param orderId Specifies the order ID 
    modifier isUnderInvestigation(uint orderId) {
        require(orders[orderId].issueStatus == IssueStatus.UnderInvestigation, "Order has not arrived so it is not under investigation!");
        _;
    }

    ///@notice Checks if the there was any issues in the quality check
    ///@param orderId Specifies the order ID 
    modifier hasFoundIssue(uint orderId) {
        require(orders[orderId].issueStatus == IssueStatus.FoundIssue, "You have not reported an issue with this order!");
        _;
    }

    ///@notice Checks if the there wasn't any issues in the quality check
    ///@param orderId Specifies the order ID 
    modifier hasNotFoundIssue(uint orderId) {
        require(orders[orderId].issueStatus != IssueStatus.FoundIssue, "An issue has been reported with this order!");
        _;
    }

    ///@notice Checks if the contract has not expired
    modifier isNotExpired() {
        require(block.timestamp <= expiryDate, "Contract has expired.");
        _;
    }
    
    ///@notice Checks if the contract has not been terminated
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

    ///@notice changes delivery status to shipped
    ///@param orderId Specifies the order ID 
    function shipOrder(uint orderId) public isSupplier isFinalized(orderId) {
        orders[orderId].deliveryStatus = DeliveryStatus.Shipped;
    }
    
    ///@notice Changes delivery status to arrived
    ///@dev Changes issueStatus to UnderInvestigation for quality check
    ///@param orderId Specifies the order ID 
    function orderArrived(uint orderId) public isShipped(orderId) isSupplier {
        orders[orderId].deliveryStatus = DeliveryStatus.Arrived;
        orders[orderId].issueStatus = IssueStatus.UnderInvestigation;
    }

    ///@notice Views the details of the order
    ///@param orderId Specifies the order ID 
    function viewOrder(uint orderId) public view returns (Order memory){
        return orders[orderId];
    }

    ///@notice Checks the status of the delivery
    ///@param orderId Specifies the order ID 
    function checkDeliveryStatus(uint orderId) public view returns (DeliveryStatus){
        return orders[orderId].deliveryStatus;
    }    

    function orderNoIssue(uint orderId) public hasArrived(orderId) isRestaurant {
        orders[orderId].issueStatus = IssueStatus.NoIssue;
    }

    /* IMPORTANT FUNCTIONS*/

    /// @notice Creates a new order
    /// @dev Doesn't set the details, but just instantiates an order
    /// @param _deliverydate Adds the delivery date to the present block timestamp
    function createOrder(uint _deliverydate) public isNotTerminated isRestaurant  {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.id = orderCount;
        newOrder.deliveryStatus = DeliveryStatus.InStorage; 
        newOrder.date = block.timestamp + _deliverydate;
    }

    /// @notice Adds ingredient to the present order
    /// @dev Checks if the ingredient is in stock in supplier
    /// @dev Checks if the required quantity of the ingredient is available
    /// @dev Checks if the specified ingredient is already in the order list
    /// @param orderId The ID of the order where the ingredients will added
    /// @param _ingredient The specific ingredient to be added
    /// @param _qty The quantity of the ingredient specified
    function addIngredient(uint orderId, string memory _ingredient, uint _qty) isNotTerminated isRestaurant public {
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Your already has been paid or finalized.");
        
        bool exists = false;
        
        string[] memory ingredientList = SupplierContractHub(parent).getSupplierIngredientsList(supplier);

        for (uint i = 0; i < ingredientList.length; i++) {
            if (keccak256(abi.encodePacked(ingredientList[i])) == keccak256(abi.encodePacked(_ingredient))) {
                exists = true;
                break;
            }
        }
        require(exists, "Ingredient does not exist in supplier stock.");

        (, int stockQty, ) = SupplierContractHub(parent).getIngredientStockDetails(supplier, _ingredient);
        require(stockQty >= int(_qty), "Not enough stock of this ingredient.");

        bool inList = false;
        
        for (uint i = 0; i < orders[orderId].ingredients.length; i++){
            if (keccak256(abi.encodePacked(orders[orderId].ingredients[i].ingredient)) == keccak256(abi.encodePacked(_ingredient))) {
                inList = true;
                break;
            }
        }
        
        if (inList == false){
            orders[orderId].ingredients.push(Item({ingredient: _ingredient, qty: _qty}));
        }
        else {
            revert("Ingredient already added to the order. Edit or remove it first");
        }
    }

    /// @notice Returns the ingredients for the specified order
    /// @param orderId The ID of the order that needs to be referenced
    function getIngredientsList(uint orderId) public view returns (Item[] memory){
        return orders[orderId].ingredients;
    }

    ///@notice Copies last order for repeat orders
    ///@dev Has the same details from the last order but the date
    ///@param date The date used to specify delivery date plus block timestamp
    function copyLastOrder(uint date) isNotTerminated isNotExpired isRestaurant public {
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

    ///@notice Edit the quantity of the specified ingredient in the order
    ///@dev Uses keccak256 hashing since Solidity can't compare strings
    ///@param orderId Specifies the order
    ///@param _ingredient Specifies the ingredient which quantity will be changed
    ///@param _qty Specifies the new quantity of the ingredient specified
    function editOrder(uint orderId, string memory _ingredient, uint _qty) isNotTerminated isNotExpired isRestaurant  public {
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

    ///@notice Checks out the specified order and accepts payment at the same time
    ///@dev It sets the final price before all the verification on the side of supplier
    ///@dev Reduces stock as well
    ///@param orderId Specifies the order ID
    function checkoutOrder(uint orderId) payable public isNotExpired isNotTerminated isRestaurant {
        Order storage currentOrder = orders[orderId];
        require(currentOrder.deliveryStatus == DeliveryStatus.InStorage, "Order already checked out or finalized.");
        uint totalCost = computePrice(orderId);
        
        orders[orderId].finalPrice = totalCost;        

        require(msg.value == totalCost, "Not the exact money sent for the order!");

        for (uint i = 0; i < currentOrder.ingredients.length; i++) {
            string memory ingredientName = currentOrder.ingredients[i].ingredient;
            uint qtyOrdered = currentOrder.ingredients[i].qty;
            SupplierContractHub(parent).stockSold(ingredientName, int(qtyOrdered));
        }
        orders[orderId].deliveryStatus = DeliveryStatus.Finalized;
    }

    ///@notice Computes the price of the order
    ///@param orderId Specifies the ID of the order to be computed
    function computePrice(uint orderId) public returns (uint price){
        uint totalCost = 0;        
        Order memory currentOrder = orders[orderId];
        for (uint i = 0; i < currentOrder.ingredients.length; i++) {
            string memory ingredientName = currentOrder.ingredients[i].ingredient;
            uint qtyOrdered = currentOrder.ingredients[i].qty;

            uint pricePerUnit = SupplierContractHub(parent).getPrice(supplier, ingredientName);
            totalCost += pricePerUnit * qtyOrdered;
        }

        uint highestDiscount = 0;
        for (uint i = 0; i < discounts.length; i++) {
            if (totalCost >= discounts[i].minimumCost) {
                if (discounts[i].percentage > highestDiscount){
                    highestDiscount = discounts[i].percentage;
                }
            }
        }
        totalCost = (totalCost * (100 - highestDiscount))/ 100;

        orders[orderId].finalPrice = totalCost;      
        return totalCost;
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
    
    function terminateContract() payable public {
        uint penalty = SupplierContractHub(parent).getSupplierPenalty(supplier);
        require(msg.value ==  penalty, "You have not paid the exact penalty fee!");
        if (msg.sender == restaurant) {
            payable(supplier).transfer(msg.value);
        } else if (msg.sender == supplier) {
            payable(restaurant).transfer(msg.value);
        }

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

    function cancelOrder(uint orderId) public isNotTerminated isRestaurant {
        require(orderId > 0 && orderId <= orderCount, "Invalid order ID");
        require(orders[orderId].deliveryStatus == DeliveryStatus.InStorage, "Order has already been processed.");

        if (orderId != orderCount) {
            orders[orderId] = orders[orderCount];
            orders[orderId].id = orderId; 
        }

        delete orders[orderCount];
        orderCount--;
    }

}