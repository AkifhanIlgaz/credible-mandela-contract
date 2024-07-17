// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrustDrops {
    function reputation(address) external view returns (uint256);
}

contract CommunityNotes {
    struct CommunityNote {
        uint256 id;
        address publisher;
        uint256 totalTipsReceived;
        string title;
        string content;
        string headImage;
        uint256 createdAt;
    }

    mapping(uint256 => CommunityNote) public notes;
    mapping(address => uint256[]) notesOfUser;
    address[] public moderators;

    address public trustDropsContract =
        0x7Fa2Addd4d59366AA98F66861d370C174DC00B46;

    uint256 public publishPrice = 10 ether;
    uint256 public minCredToPublish = 1000;
    address public owner;

    uint256 public notesPerPage = 5;
    uint256 private noteIdCounter;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyModeratorOrOwner() {
        bool isModerator = false;
        for (uint i = 0; i < moderators.length; i++) {
            if (moderators[i] == msg.sender) {
                isModerator = true;
                break;
            }
        }
        require(
            msg.sender == owner || isModerator,
            "Only moderator or owner can perform this action"
        );
        _;
    }

    function setPublishPrice(uint256 _newPrice) public onlyOwner {
        publishPrice = _newPrice;
    }

    function setNotesPerPage(uint256 _notesPerPage) public onlyOwner {
        notesPerPage = _notesPerPage;
    }

    function setMinCredToPublish(uint256 _minCredToPublish) public onlyOwner {
        minCredToPublish = _minCredToPublish;
    }

    function addModerator(address _newModerator) public onlyOwner {
        require(_newModerator != address(0), "Invalid moderator address");
        for (uint i = 0; i < moderators.length; i++) {
            require(
                moderators[i] != _newModerator,
                "Address is already a moderator"
            );
        }
        moderators.push(_newModerator);
    }

    function deleteModerator(address _moderator) public onlyOwner {
        require(_moderator != address(0), "Invalid moderator address");
        bool found = false;
        for (uint i = 0; i < moderators.length; i++) {
            if (moderators[i] == _moderator) {
                moderators[i] = moderators[moderators.length - 1];
                moderators.pop();
                found = true;
                break;
            }
        }
        require(found, "Address is not a moderator");
    }

    function publishNote(
        string memory _title,
        string memory _content,
        string memory headImage
    ) public payable {
        require(
            getReputationOfUser(msg.sender) >= minCredToPublish,
            "Insufficient reputation"
        );
        require(msg.value >= publishPrice, "Insufficient payment for ad");
        require(
            bytes(_title).length <= 100,
            "Title exceeds 100 character limit"
        );
        require(
            bytes(_content).length <= 500,
            "Content exceeds 500 character limit"
        );

        uint256 noteId = noteIdCounter;
        noteIdCounter++;

        notes[noteId] = CommunityNote({
            id: noteId,
            publisher: msg.sender,
            title: _title,
            content: _content,
            createdAt: block.timestamp,
            totalTipsReceived: 0,
            headImage: headImage
        });

        notesOfUser[msg.sender].push(noteId);
    }

    function getNotes(
        uint256 page
    ) public view returns (CommunityNote[] memory) {
        require(page > 0, "Page must be greater than 0");

        uint256 startIndex = (page - 1) * notesPerPage;
        uint256 endIndex = min(startIndex + notesPerPage, noteIdCounter);

        require(startIndex < noteIdCounter, "Page exceeds available notes");

        uint256 resultLength = endIndex - startIndex;
        CommunityNote[] memory result = new CommunityNote[](resultLength);

        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = notes[startIndex + i];
        }

        return result;
    }

    function getNotesOfUser(
        address user
    ) public view returns (CommunityNote[] memory) {
        uint256[] storage userNoteIds = notesOfUser[user];
        uint256 totalUserNotes = userNoteIds.length;

        CommunityNote[] memory result = new CommunityNote[](totalUserNotes);

        for (uint256 i = 0; i < totalUserNotes; i++) {
            uint256 noteId = userNoteIds[i];
            result[i] = notes[noteId];
        }

        return result;
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function deletePost(uint256 noteId) public onlyModeratorOrOwner {
        require(noteId < noteIdCounter, "Note does not exist");

        address publisher = notes[noteId].publisher;

        delete notes[noteId];

        uint256[] storage authorNotes = notesOfUser[publisher];
        for (uint i = 0; i < authorNotes.length; i++) {
            if (authorNotes[i] == noteId) {
                authorNotes[i] = authorNotes[authorNotes.length - 1];
                authorNotes.pop();
                break;
            }
        }
    }

    function tipNote(uint256 _noteId) public payable {
        require(_noteId < noteIdCounter, "Note does not exist");
        require(msg.value > 0, "Tip amount must be greater than 0");

        CommunityNote storage note = notes[_noteId];
        address payable author = payable(note.publisher);

        require(author != msg.sender, "You cannot tip your own note");

        note.totalTipsReceived += msg.value;

        (bool sent, ) = author.call{value: msg.value}("");
        require(sent, "Failed to send tip to the author");
    }

    function getReputationOfUser(address _user) public view returns (uint256) {
        ITrustDrops trustDrops = ITrustDrops(trustDropsContract);

        return trustDrops.reputation(_user);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
