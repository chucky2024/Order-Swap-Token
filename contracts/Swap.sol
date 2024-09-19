
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapTokens {
    struct Order {
        address user; // user's address
        address tokenDeposited; // token that was deposited
        uint256 tokenGiven; // token amount exchanged
        address tokenDesired; // token symbol that was wanted by user
        uint256 tokenExchanged; // token amount to be sent to the user
        bool hasExchanged; // has the order been completed
    }

    mapping(address => Order) public orders; // to map orders
    mapping(address => mapping(address => uint256)) public balanceOfUser; // user balances by token pairs

    // Create a new order
    function createOrder(address _tokenDeposited, address _tokenDesired, uint256 _tokenGiven, uint256 _tokenExchanged) public {
        require(msg.sender != address(0), "Address zero not accepted!");
        require(_tokenDeposited != address(0), "Invalid token");
        require(_tokenDesired != address(0), "Invalid token");
        require(_tokenGiven > 0, "Tokens should be greater than zero");
        require(_tokenExchanged > 0, "Tokens should be greater than zero");
        require(orders[msg.sender].tokenDeposited == address(0), "You already have an active order");

        // Create the order
        orders[msg.sender] = Order(msg.sender, _tokenDeposited, _tokenGiven, _tokenDesired, _tokenExchanged, false);
        balanceOfUser[_tokenDeposited][_tokenDesired] += _tokenGiven;

        // Transfer tokens from user to the contract
        IERC20(_tokenDeposited).transferFrom(msg.sender, address(this), _tokenGiven);
    }

    // Execute an existing order
    function executeOrder(address _user) public {
        Order storage order = orders[_user];
        require(order.user != address(0), "Order does not exist");
        require(order.hasExchanged == false, "Order already completed!");
        require(balanceOfUser[order.tokenDeposited][order.tokenDesired] >= order.tokenGiven, "Insufficient balance");

        // Execute the swap
        balanceOfUser[order.tokenDeposited][order.tokenDesired] -= order.tokenGiven;
        IERC20(order.tokenDesired).transferFrom(msg.sender, address(this), order.tokenExchanged);
        IERC20(order.tokenDeposited).transfer(msg.sender, order.tokenGiven);

        order.hasExchanged = true; // Mark order as completed
    }

    // Cancel an existing order
    function cancelOrder() public {
        Order storage order = orders[msg.sender];
        require(order.user != address(0), "Order does not exist");
        require(order.hasExchanged == false, "Cannot cancel a completed order");

        // Return deposited tokens to the user
        IERC20(order.tokenDeposited).transfer(msg.sender, order.tokenGiven);
        delete orders[msg.sender]; // Delete the order
    }
}
