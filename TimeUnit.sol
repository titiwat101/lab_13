
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeUnit {
    uint256 private startTime;

    constructor() {
        startTime = block.timestamp;
    }

    function elapsedSeconds() public view returns (uint256) {
        return block.timestamp - startTime;
    }

    function resetTime() public {
        startTime = block.timestamp;
    }
}
