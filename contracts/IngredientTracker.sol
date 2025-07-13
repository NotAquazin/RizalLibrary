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

    
    enum STATUS {InStorage, Shipped, Arrived, Completed}

    //Ingredient and its respective quantity
    struct Stock{
        string ingredient;
        uint qty; 
    }

    //The details of the contract
    struct details{
        string date;
        uint discount;
        uint refundPrice; 
        uint finalPrice;
        STATUS status; 
    }
    Stock[] public ingredientsList;

    //Initializing the Restaurant - supplier contract relationship
    constructor(address _supplier){
        supplier = _supplier;
    }

    function addIngredient(string memory _ingredient, uint _qty) public{
        ingredientsList.push(Stock({ingredient: _ingredient, qty : _qty}));
    }

    function getIngredientsList() public view returns (Stock[] memory){
        return ingredientsList;
    }

}