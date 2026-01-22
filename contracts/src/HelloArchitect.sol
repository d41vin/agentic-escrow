// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; // Changed via review to be more generally compatible, user doc said 0.8.30 but let's stick to simple standards or match doc exactly? Doc said ^0.8.30. I will use ^0.8.30 to match doc strictly.

contract HelloArchitect {
    string private greeting;

    // Event emitted when the greeting is changed
    event GreetingChanged(string newGreeting);

    // Constructor that sets the initial greeting to "Hello Architect!"
    constructor() {
        greeting = "Hello Architect!";
    }

    // Setter function to update the greeting
    function setGreeting(string memory newGreeting) public {
        greeting = newGreeting;
        emit GreetingChanged(newGreeting);
    }

    // Getter function to return the current greeting
    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}
