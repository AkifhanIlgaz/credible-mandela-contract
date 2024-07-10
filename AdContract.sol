// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdPlatform {
    struct Ad {
        uint256 stakeAmount;
        bool isActive;
        uint256 createdAt;
    }

    struct AdWithAddress {
        address advertiser;
        uint256 stakeAmount;
        uint256 createdAt;
    }

    mapping(address => Ad[]) public userAds;
    address[] public advertisers;
    uint256 public totalAdCount;
    uint256 public adPrice = 1 ether;
    address public owner;

    constructor() {
        owner = msg.sender;

        advertisers = [
            0xF5A2Ea40Ebf2517F60857228d1b08AC6433e4C5C,
            0xcF7Cb092228cF9A9a7D8874665C06D3E2CE45A14,
            0x32831261807A3F6Fc84c815C7EB2797764b46040,
            0x025314ADd0264185B8d2866d99fB0b62C8613bd9,
            0xC4fCF1336567bff5F1E5ed095aab304b00AC602a
        ];

        userAds[0xF5A2Ea40Ebf2517F60857228d1b08AC6433e4C5C].push(
            Ad({
                stakeAmount: 1 ether,
                isActive: true,
                createdAt: block.timestamp
            })
        );

        userAds[0xcF7Cb092228cF9A9a7D8874665C06D3E2CE45A14].push(
            Ad({
                stakeAmount: 1 ether,
                isActive: true,
                createdAt: block.timestamp
            })
        );

        userAds[0x32831261807A3F6Fc84c815C7EB2797764b46040].push(
            Ad({
                stakeAmount: 1 ether,
                isActive: true,
                createdAt: block.timestamp
            })
        );

        userAds[0x025314ADd0264185B8d2866d99fB0b62C8613bd9].push(
            Ad({
                stakeAmount: 4 ether,
                isActive: true,
                createdAt: block.timestamp
            })
        );

        userAds[0xC4fCF1336567bff5F1E5ed095aab304b00AC602a].push(
            Ad({
                stakeAmount: 4 ether,
                isActive: true,
                createdAt: block.timestamp
            })
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setAdPrice(uint256 _newPrice) public onlyOwner {
        adPrice = _newPrice;
    }

    function publishAd(uint256 stakeAmount) public payable {
        require(msg.value >= adPrice, "Insufficient payment for ad");
        require(stakeAmount > 0, "Stake amount can't be zero");

        if (userAds[msg.sender].length == 0) {
            advertisers.push(msg.sender);
        }

        userAds[msg.sender].push(
            Ad({
                stakeAmount: stakeAmount,
                isActive: true,
                createdAt: block.timestamp
            })
        );

        totalAdCount++;
    }

    function getAds(address _user) public view returns (Ad[] memory) {
        uint256 totalActiveAds = 0;
        for (uint256 i = 0; i < userAds[_user].length; i++) {
            if (userAds[_user][i].isActive) {
                totalActiveAds++;
            }
        }

        Ad[] memory activeAds = new Ad[](totalActiveAds);
        uint256 index = 0;
        for (uint256 i = 0; i < userAds[_user].length; i++) {
            if (userAds[_user][i].isActive) {
                activeAds[index] = userAds[_user][i];
                index++;
            }
        }

        return activeAds;
    }

    function republishAd(uint256 stakeAmount) public payable {
        require(msg.value >= adPrice, "Insufficient payment for republishing");

        bool adFound = false;
        for (uint256 i = 0; i < userAds[msg.sender].length; i++) {
            Ad storage ad = userAds[msg.sender][i];
            if (ad.stakeAmount == stakeAmount && ad.isActive) {
                ad.createdAt = block.timestamp;
                adFound = true;
                break;
            }
        }

        totalAdCount++;

        require(adFound, "No active ad found with the specified stake amount");
    }

    function getUserAdCount(address _user) public view returns (uint256) {
        return userAds[_user].length;
    }

    function deleteAd(uint256 _stakeAmount) public {
        Ad[] storage ads = userAds[msg.sender];
        for (uint256 i = 0; i < ads.length; i++) {
            if (ads[i].stakeAmount == _stakeAmount && ads[i].isActive) {
                ads[i].isActive = false;
                break;
            }
        }
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function getAllActiveAds() public view returns (AdWithAddress[] memory) {
        // Count the total number of active ads first
        uint256 totalActiveAds = 0;
        for (uint256 i = 0; i < advertisers.length; i++) {
            Ad[] storage userAdArray = userAds[advertisers[i]];
            for (uint256 j = 0; j < userAdArray.length; j++) {
                if (userAdArray[j].isActive) {
                    totalActiveAds++;
                }
            }
        }

        // Create a fixed-size array in memory
        AdWithAddress[] memory allActiveAds = new AdWithAddress[](
            totalActiveAds
        );
        uint256 currentIndex = 0;

        // Populate the array
        for (uint256 i = 0; i < advertisers.length; i++) {
            address advertiser = advertisers[i];
            Ad[] storage userAdArray = userAds[advertiser];
            for (uint256 j = 0; j < userAdArray.length; j++) {
                if (userAdArray[j].isActive) {
                    allActiveAds[currentIndex] = AdWithAddress({
                        createdAt: userAdArray[j].createdAt,
                        advertiser: advertiser,
                        stakeAmount: userAdArray[j].stakeAmount
                    });
                    currentIndex++;
                }
            }
        }

        return allActiveAds;
    }

    function getAdPrice() public view returns (uint256) {
        return adPrice;
    }
}
