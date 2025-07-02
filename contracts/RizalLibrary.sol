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

contract RizalLibrary {

    address internal librarian;

    struct Book {
        uint bookCallNum;
        int borrowDeadline;
    }

    struct Student {
        uint idnumber;
        string name;
        uint balance;
        bool hasBorrowed;
        bool hasHoldOrder;
        Book bookBorrowed;
    }

    mapping(address => Student) public students;

    modifier noHoldOrder() {
        require(students[msg.sender].hasHoldOrder == false, "You have a Hold Order. Not allowed to borrow!");
        _;
    }

    modifier hasHoldOrder(){
        require(students[msg.sender].hasHoldOrder == true, "You do not have a Hold Order. You do not have an outstanding balance");
        _;
    }

    modifier isStudent() {
        require(msg.sender != librarian , "You are not a student!");
        _;
    }

    modifier noBorrowedBook() {
        require(!students[msg.sender].hasBorrowed, "You already borrowed. Not allowed to borrow more!");
        _;
    }

    modifier hasBorrowedBook() {
        require(students[msg.sender].hasBorrowed, "You have not borrowed a book yet!");
        _;
    }

    modifier notEnrolled() {
        require(students[msg.sender].idnumber == 0, "You are already enrolled!");
        _;
    }

    modifier isEnrolled() {
        require(students[msg.sender].idnumber > 0, "You are not yet enrolled!");
        _;
    }

    event StudentEnrolled(address indexed studentAddress, uint idnumber);
    event BookBorrowed(uint bookCallNum, address indexed studentAddress);
    event StudentPaid(address indexed studentAddress, uint paid);

    constructor() {
        librarian = msg.sender;
    }

    function addStudent(address _student) public isStudent notEnrolled {
        //adds student to students list with given id number and name
        

    }

    function borrow(uint _bookCallNum) external isEnrolled noBorrowedBook {
        //checks if student is allowed to borrow a book
        //something that will say the book is borrowed
        //emit book
    }

    function returnBook() external isEnrolled hasBorrowedBook {
        //no need for parameter since there's only 1 book per student
        //this will let student to return the book, check if student has borrowed a book (checked through the modifier)

        //if yes then check it is returned within the deadline.
        //If past deadline, add the penalty to the student (hold order and balance)
    }

    function payBalance() external payable hasHoldOrder {
        //checks if student has an outstanding balance or hold order
        //if so, subtract the amount paid from their balance and set the student hasBorrowed to false. If not, then tell them that they do not have a valid hold order (or outstanding balance)
        //emit event for payment
    }
}