
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS {
    CommitReveal private commitReveal;
    TimeUnit private timeunit;

    address[2] private players;
    uint256 private numPlayer = 0;
    uint256 private numInput = 0;
    uint256 private reward = 0;

    mapping(address => uint256) private player_choice;
    mapping(address => bool) private player_not_played;

    constructor(address _commitReveal, address _timeUnit) {
        commitReveal = CommitReveal(_commitReveal);
        timeunit = TimeUnit(_timeUnit);
    }

    function joinGame() public payable {
        require(numPlayer < 2, "Game is full");
        require(msg.value > 0, "Must bet some ETH");

        players[numPlayer] = msg.sender;
        player_not_played[msg.sender] = true;
        numPlayer++;
        reward += msg.value;
    }

    function commitChoice(bytes32 _commitment) public {
        require(numPlayer == 2, "Game not full yet");
        commitReveal.commitMove(msg.sender, _commitment);
    }

    function revealChoice(uint256 _choice, string memory _salt) public {
        require(numPlayer == 2, "Game not full yet");
        require(commitReveal.reveal(msg.sender, _choice, _salt), "Reveal failed");

        player_choice[msg.sender] = _choice;
        numInput++;
        player_not_played[msg.sender] = false;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint256 p0Choice = player_choice[players[0]];
        uint256 p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3) % 5 == p1Choice) {
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            account0.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetGame();
    }

    function forceGame() public {
        require(numPlayer == 2, "Not enough players");
        require(timeunit.elapsedSeconds() > 600, "Wait more time");

        payable(players[0]).transfer(reward / 2);
        payable(players[1]).transfer(reward / 2);

        resetGame();
    }

    function Callback() public {
        require(numPlayer == 1, "Game is not stuck");
        require(timeunit.elapsedSeconds() > 300, "Wait more time");

        payable(players[0]).transfer(reward);
        resetGame();
    }

    function resetGame() private {
        numPlayer = 0;
        numInput = 0;
        reward = 0;
        delete players;
    }
}
