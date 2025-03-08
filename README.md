# lab_13

⸻

1. โค้ดที่ป้องกันการล็อกเงินในสัญญา (Contract)

ใน RPS.sol มีการป้องกันไม่ให้เงินถูกล็อกไว้ในสัญญาโดยใช้ฟังก์ชัน forceGame() และ Callback() ซึ่งจะทำการคืนเงินให้ผู้เล่นหากเกิดความล่าช้า

ฟังก์ชัน forceGame()

function forceGame() public payable {
    require(numPlayer == 2);
    require(player_not_played[msg.sender] == false);
    require(timeunit.elapsedSeconds() > 600);
    payable(players[0]).transfer(reward / 2);
    payable(players[1]).transfer(reward / 2);
    numPlayer = 0;
    reward = 0;
    numInput = 0;
    delete players;
}

ใช้ require(timeunit.elapsedSeconds() > 600); เพื่อตรวจสอบว่าเวลาผ่านไปเกิน 10 นาที
หากผู้เล่นไม่ส่ง input ครบตามเวลาที่กำหนด เงินรางวัลจะถูกแบ่งคืนให้ทั้งสองฝ่าย

ฟังก์ชัน Callback()

function Callback() public payable {
    require(numPlayer == 1);
    require(timeunit.elapsedSeconds() > 300);
    if (timeunit.elapsedSeconds() > 300) {
        payable(players[0]).transfer(reward);
    }
    numPlayer = 0;
    reward = 0;
    numInput = 0;
    delete players;
}
ใช้ตรวจสอบกรณีมีผู้เล่นเพียงคนเดียวและรอเกิน 5 นาที (timeunit.elapsedSeconds() > 300)
เงินเดิมพันทั้งหมดจะคืนให้กับผู้เล่นที่ยังอยู่ในเกม

⸻

2. โค้ดส่วนที่ทำการซ่อน (commit) และเปิดเผย (reveal) ตัวเลือก

การซ่อนและเปิดเผยตัวเลือกของผู้เล่นถูกจัดการใน CommitReveal.sol และถูกเรียกใช้ใน RPS.sol

การซ่อน (Commit)

function commitMove(address player, bytes32 _commitment, uint256 _choice, string memory _salt) public {
    require(commits[player].commit == bytes32(0), "Already committed");
    commits[player] = Commitment(_commitment, _choice, _salt);
}

commitment คือค่าแฮชของตัวเลือกที่ผู้เล่นเลือก (choice) และค่าลับ (salt)
บันทึกค่า _commitment ลงใน mapping commits
	ใช้ require(commits[player].commit == bytes32(0), "Already committed"); เพื่อป้องกันการเปลี่ยนค่า

การเปิดเผย (Reveal)

function reveal(address player) public view returns (bool) {
    require(commits[player].commit != bytes32(0), "CommitReveal::reveal: No commit found");
    require(keccak256(abi.encode(commits[player].choice, commits[player].salt)) == commits[player].commit, "CommitReveal::reveal: Revealed hash does not match commit");
    return true;
}

ใช้ keccak256 ตรวจสอบว่าค่าที่เปิดเผย (choice และ salt) ตรงกับ _commitment ที่เคยบันทึกไว้หรือไม่
	หากตรงกัน จะคืนค่า true


3. โค้ดที่จัดการกับความล่าช้าของผู้เล่น

ใน RPS.sol มีการจัดการกับกรณีที่ผู้เล่นไม่ดำเนินการตามกำหนด

เช็คว่าผู้เล่นป้อนค่าเกินเวลาหรือไม่

require(timeunit.elapsedSeconds() > 600);

ใช้ elapsedSeconds() จาก TimeUnit.sol เพื่อนับเวลาตั้งแต่เริ่มเกม
หากเกิน 10 นาที (600 วินาที), ฟังก์ชัน forceGame() จะถูกเรียกใช้

การคืนเงินหากมีผู้เล่นเพียงคนเดียว

if (timeunit.elapsedSeconds() > 300) {
    payable(players[0]).transfer(reward);
}

	หากผ่านไป 5 นาที และมีเพียงผู้เล่นคนเดียว (numPlayer == 1), เงินจะถูกโอนไปให้ผู้เล่นที่รออยู่

⸻

4. โค้ดที่ทำการ reveal และนำ choice มาตัดสินผู้ชนะ

ใน RPS.sol ฟังก์ชัน _checkWinnerAndPay() ทำหน้าที่ตัดสินผู้ชนะและจ่ายเงินรางวัล

ฟังก์ชัน _checkWinnerAndPay()

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

วิธีตัดสินผู้ชนะ
ผู้เล่น 1 (p0Choice) ชนะผู้เล่น 2 (p1Choice) หาก
	(p0Choice + 1) % 5 == p1Choice (กฎปกติของ Rock-Paper-Scissors-Lizard-Spork)
	(p0Choice + 3) % 5 == p1Choice (เพิ่มตัวเลือก Lizard และ Spork)
	ผู้เล่น 2 (p1Choice) ชนะผู้เล่น 1 (p0Choice) หาก
(p1Choice + 1) % 5 == p0Choice
 (p1Choice + 3) % 5 == p0Choice
ถ้าทั้งสองเลือกเหมือนกัน แบ่งเงินครึ่งหนึ่งให้ทั้งสองฝ่าย
