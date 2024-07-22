// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// *CC - Contewnt Creator
// *CL - client

contract sendPost {
    struct AdDetails {
        // address payable client;
        address payable contentCreatorAddress; // address of CC
        address payable postOwner; // address of the CL, creating the ad
        string postText; // text in the post
        uint256 totalPayment; // payment offered to CC
        uint256 postDurationInHours; // Duration in seconds
        bool isAccepted; // boolean - is ad from CL accepted by CC
        string postURL; // url of the post to check - should be provided by CC
        string status;
        // uint256 startTime; // Timestamp of ad creation
    }

    // mapping: CC address to ad (to ensure correct CC receives the ad)
    mapping(address => AdDetails) public listOfContentCreatorAndAd;

    // Event triggered when a content creator accepts/rejects an offer
    event OfferAccepted(address contentCreator, address postOwner);
    event OfferRejected(address contentCreator, address postOwner);

    // Function for clients to create new ads
    function createAd(
        address payable _contentCreatorAddress,
        string memory _postText,
        uint256 _totalPayment,
        uint256 _postDurationInHours
    ) public payable {
        require(
            !listOfContentCreatorAndAd[_contentCreatorAddress].isAccepted,
            "Offer already accepted"
        ); // Prevent duplicate acceptance
        require(msg.value == _totalPayment, "Insufficient payment provided"); // require lock of the funds

        listOfContentCreatorAndAd[_contentCreatorAddress] = AdDetails({
            contentCreatorAddress: _contentCreatorAddress,
            postOwner: payable(msg.sender),
            postText: _postText,
            totalPayment: _totalPayment,
            postDurationInHours: _postDurationInHours,
            isAccepted: false,
            postURL: "",
            status: "Pending"
        });
    }

    function acceptOffer(string memory _postURL) public {
        AdDetails storage adDetails = listOfContentCreatorAndAd[msg.sender];
        require(
            adDetails.contentCreatorAddress == msg.sender,
            "Only authorized content creator can accept"
        );
        require(!adDetails.isAccepted, "Offer already accepted");
        require(bytes(_postURL).length != 0, "URL not provided");

        adDetails.isAccepted = true;
        adDetails.postURL = _postURL;
        adDetails.status = "Ongoing";
        emit OfferAccepted(msg.sender, adDetails.postOwner);

        // Lock funds in the contract upon acceptance
        // payable(adDetails.contentCreatorAddress).transfer(adDetails.totalPayment);
    }

    function rejectOffer() public {
        AdDetails storage adDetails = listOfContentCreatorAndAd[msg.sender];
        require(
            adDetails.contentCreatorAddress == msg.sender,
            "Only authorized content creator can reject"
        );
        adDetails.isAccepted = false;
        adDetails.status = "Cancelled";

        payable(adDetails.postOwner).transfer(adDetails.totalPayment);
        emit OfferRejected(msg.sender, adDetails.postOwner);
    }

    function compareContentMatchSuccess(string calldata _match) public {
        AdDetails storage adDetails = listOfContentCreatorAndAd[msg.sender];

        if (
            keccak256(abi.encodePacked(_match)) ==
            keccak256(abi.encodePacked("Yes"))
        ) {
            payable(adDetails.contentCreatorAddress).transfer(
                adDetails.totalPayment
            );
        } else if (
            keccak256(abi.encodePacked(_match)) ==
            keccak256(abi.encodePacked("No"))
        ) {
            payable(adDetails.postOwner).transfer(adDetails.totalPayment);
        }
        // keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
}
