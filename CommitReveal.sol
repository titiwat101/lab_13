
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitReveal {
    struct Commitment {
        bytes32 commit;
        uint256 choice;
        string salt;
    }

    mapping(address => Commitment) private commits;

    function commitMove(address player, bytes32 _commitment) public {
        require(commits[player].commit == bytes32(0), "Already committed");
        commits[player] = Commitment(_commitment, 0, "");
    }

    function reveal(address player, uint256 _choice, string memory _salt) public view returns (bool) {
        require(commits[player].commit != bytes32(0), "No commit found");
        require(keccak256(abi.encode(_choice, _salt)) == commits[player].commit, "Hash does not match");

        return true;
    }
}
