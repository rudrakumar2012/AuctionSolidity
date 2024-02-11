// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import SafeMath for safe arithmetic operations
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Auction {
    using SafeMath for uint256; // Use SafeMath for all uint256 operations

    struct AuctionDetails {
        address payable owner; // Address of the auction creator
        address payable highestBidder; // Address of the current highest bidder
        uint256 startingPrice; // Initial price of the auction
        uint256 minimumBidIncrement; // Minimum amount each bid must increase by
        uint256 currentHighestBid; // Current highest bid amount
        uint256 startTime; // Start time of the auction (timestamp)
        uint256 endTime; // End time of the auction (timestamp)
        bool auctionEnded; // Flag indicating whether the auction has ended
    }

    mapping(address => uint256[]) private userAuctions; // Mapping of user address to auction IDs
    mapping(uint256 => AuctionDetails) public auctions; // Mapping of auction ID to auction details

    // Modifier to ensure the sender is not the owner of the auction
    modifier notOwnerOfAuction(uint256 auctionId) {
        require(msg.sender != auctions[auctionId].owner, "Cannot bid on your own auction");
        _;
    }

    // Function to create a new auction
    function createAuction(
        uint256 startingPriceInWei,
        uint256 minimumBidIncrementInWei,
        uint256 durationInMinutes
    ) public payable {
        require(msg.value >= startingPriceInWei, "Initial bid must be equal to or greater than starting price");
        uint256 endTime = block.timestamp.add(durationInMinutes.mul(1 minutes));
        require(endTime > block.timestamp, "End time must be in the future");

        uint256 auctionId = userAuctions[msg.sender].length; // Get next auction ID for user
        auctions[auctionId] = AuctionDetails({
            owner: payable(msg.sender),
            highestBidder: payable(address(0)), // Initialize highest bidder to zero address
            startingPrice: startingPriceInWei,
            minimumBidIncrement: minimumBidIncrementInWei,
            currentHighestBid: startingPriceInWei,
            startTime: block.timestamp,
            endTime: endTime,
            auctionEnded: false
        });
        userAuctions[msg.sender].push(auctionId); // Add auction ID to user's list
    }

    // ... rest of the contract remains unchanged

    // Function to place a bid on an auction
    function placeBid(uint256 auctionId, uint256 bidAmountInWei) public payable notOwnerOfAuction(auctionId) {
        AuctionDetails storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(bidAmountInWei > auction.currentHighestBid + auction.minimumBidIncrement, "Bid must be higher than current highest bid with increment");
        require(msg.value >= bidAmountInWei, "Insufficient funds for bid");

        // Refund previous highest bidder if any
        if (auction.highestBidder != address(0)) {
            auction.highestBidder.transfer(auction.currentHighestBid);
        }

        auction.highestBidder = payable(msg.sender);
        auction.currentHighestBid = bidAmountInWei;
    }

    // Function for the auction owner to end the auction
    function endAuction(uint256 auctionId) public {
        AuctionDetails storage auction = auctions[auctionId];
        require(msg.sender == auction.owner, "Only auction owner can end the auction");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        require(!auction.auctionEnded, "Auction already ended");

        auction.auctionEnded = true;

        // Transfer highest bid to owner (assuming no escrow)
        auction.owner.transfer(auction.currentHighestBid);
    }

    // Function to get details of a specific auction
    function getAuctionDetails(uint256 auctionId) public view returns (AuctionDetails memory) {
        require(auctions[auctionId].owner != address(0), "Invalid auction ID");
        return auctions[auctionId];
    }

    // Function to get all auctions created by a specific user
    function getMyAuctions(address user) public view returns (uint256[] memory) {
        return userAuctions[user];
    }
}
