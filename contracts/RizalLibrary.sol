// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/* We hereby attest to the truth of the following facts:
*
*  We have not discussed the solidity code in our program with anyone
*  other than our instructor or the teaching assistants assigned to this course.
*
*  We have not used solidity code obtained from another student, or
*  any other unauthorized source, whether modified or unmodified.
*
*  If any solidity code or documentation used in our program was
*  obtained from another source, it has been clearly noted with citations in the
*  comments of our program.
*/

/** 
 * @title RizalLibrary
 * @dev Implement a smart contract for the rizal library that stores students details
 * tracks the borrowing of books, and assists with the payment of fees  
 */

contract RizalLibrary {

    address internal librarian; // Adress of Librarian 

    /*
     * Stores book details
     */
    struct Book {
        uint bookCallNum; //Number of the book
        int borrowDeadline; //deadline of the borrowed book
    }

    /*
     * Stores students details
     */
    struct Student {
        uint idnumber; 
        string name;
        uint balance;
        bool hasBorrowed;
        bool holdOrder;
        Book bookBorrowed;
    }

    /*
     * Mapping of the address to the student
     */
    mapping(address => Student) private students;

    
    /*
     * Checks if the student does not have a hold order 
     */
    modifier noHoldOrder() {
        require(students[msg.sender].holdOrder == false, "You have a Hold Order. Not allowed to borrow!");
        _;
    }

    /*
     * Checks if the student has a hold order.
     */
    modifier hasHoldOrder(){
        require(students[msg.sender].holdOrder == true, "You do not have a Hold Order. You do not have an outstanding balance");
        _;
    }

    /*
     * Checks if the person is a student 
     */
    modifier isStudent() {
        require(msg.sender != librarian , "You are not a student!");
        _;
    }
    
    /*
     * Checks if the person is a librarian 
     */
    modifier isLibrarian() {
        require(msg.sender == librarian, "You are not a librarian!");
        _;
    }

    /*
     * Checks if the student does not have a borrowed book
     */
    modifier noBorrowedBook() {
        require(!students[msg.sender].hasBorrowed, "You already borrowed. Not allowed to borrow more!");
        _;
    }

    /*
     * Checks if the student has a borrowed book
     */
    modifier hasBorrowedBook() {
        require(students[msg.sender].hasBorrowed, "You have not borrowed a book yet!");
        _;
    }

    /*
     * Checks if the student is enrolled
     */
    modifier isEnrolled() {
        require(students[msg.sender].idnumber > 0, "You are not yet enrolled!");
        _;
    }

    /*
     * Event logs
     */
    event StudentEnrolled(address indexed studentAddress, uint idnumber);
    event BookBorrowed(uint bookCallNum, address indexed studentAddress);
    event StudentPaid(address indexed studentAddress, uint paid);


     /*
     * Constructor function
     * Initializing the librarian
     */
    constructor() {
        librarian = msg.sender;
    }

    /*
     * Adding a student by inputing a name and idnum
     * @param _student the address of the person you will enroll
     * @param _idnumber the idnumber you will give to the student 
     * @param _name the name you will give the student 
     */
    function addStudent(address _student, uint _idnumber, string memory _name) public isLibrarian {
        require(students[_student].idnumber == 0, "Student already enrolled!");
        students[_student].idnumber = _idnumber ;
        students[_student].name = _name ;
    }

    /*
     * Allows the student to borrow a book
     * @param _bookCallNum the number of the book
     */
    function borrow(uint _bookCallNum) external isStudent isEnrolled noHoldOrder noBorrowedBook {
        students[msg.sender].hasBorrowed = true;
        students[msg.sender].bookBorrowed = Book(_bookCallNum, int(block.timestamp + 2 weeks));
        emit BookBorrowed(_bookCallNum, msg.sender);
    }

    /*
     * Allows the student to return the book
     */
    function returnBook() external isStudent isEnrolled hasBorrowedBook {
        int current = int(block.timestamp);
        if (current >= students[msg.sender].bookBorrowed.borrowDeadline) {
            students[msg.sender].holdOrder = true;
            students[msg.sender].balance = 50000 wei;
        }
        students[msg.sender].hasBorrowed = false;
        students[msg.sender].bookBorrowed = Book(0 , 0);
    }

    /*
     * Allows the student to pay their fees 
     */
    function payBalance() external payable isStudent isEnrolled hasHoldOrder {
        require(students[msg.sender].balance == msg.value, "Please pay the exact amount of the fine");
        students[msg.sender].balance -= msg.value;
        students[msg.sender].holdOrder = false;
        emit StudentPaid(msg.sender, msg.value);
    }
}