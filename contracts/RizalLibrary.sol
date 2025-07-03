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
        bool holdOrder;
        Book bookBorrowed;
    }

    mapping(address => Student) private students;

    modifier noHoldOrder() {
        require(students[msg.sender].holdOrder == false, "You have a Hold Order. Not allowed to borrow!");
        _;
    }

    modifier hasHoldOrder(){
        require(students[msg.sender].holdOrder == true, "You do not have a Hold Order. You do not have an outstanding balance");
        _;
    }

    modifier isStudent() {
        require(msg.sender != librarian , "You are not a student!");
        _;
    }
    
    modifier isLibrarian() {
        require(msg.sender == librarian, "You are not a librarian!");
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

    function addStudent(address _student, uint _idnumber, string memory _name) public isLibrarian {
        require(students[_student].idnumber == 0, "Student already enrolled!");
        students[_student].idnumber = _idnumber ;
        students[_student].name = _name ;
    }

    function borrow(uint _bookCallNum) external isStudent isEnrolled noHoldOrder noBorrowedBook {
        students[msg.sender].hasBorrowed = true;
        students[msg.sender].bookBorrowed = Book(_bookCallNum, int(block.timestamp + 2 weeks));
        emit BookBorrowed(_bookCallNum, msg.sender);
    }

    function returnBook() external isStudent isEnrolled hasBorrowedBook {
        int current = int(block.timestamp);
        if (current >= students[msg.sender].bookBorrowed.borrowDeadline) {
            students[msg.sender].holdOrder = true;
            students[msg.sender].balance = 50000 wei;
        }
        students[msg.sender].hasBorrowed = false;
        students[msg.sender].bookBorrowed = Book(0 , 0);
    }

    function payBalance() external payable isStudent isEnrolled hasHoldOrder {
        require(students[msg.sender].balance == msg.value, "Please pay the exact amount of the fine");
        students[msg.sender].balance -= msg.value;
        students[msg.sender].holdOrder = false;
        emit StudentPaid(msg.sender, msg.value);
    }
}