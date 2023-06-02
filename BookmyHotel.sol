// SPDX-License-Identifier: MIT

// Hotel Booking

pragma solidity ^0.8.0;

contract BookmyHotel {
    enum Statuses {
        Occupied,
        Vacant
    }

    struct Booking {
        address payable owner;
        bool checkedOut;
        bool cancelled;
        uint256 amountPaid;
    }

    Statuses public currentStatus;

    address payable public owner;

    mapping(address => Booking) bookings;

    event Occupy(address _address, uint256 amount);
    event TransferSuccess(address sender, address recipient, uint256);
    event TransferFailed(address sender, address recipient, uint256 amount); // the amount parameter is necessary to indicate the amount of funds that failed to be transferred.
    event CheckoutFailed(address sender);
    event BookingCancelled(address indexed owner, uint256 amountRefunded);

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Statuses.Vacant;
    }

    modifier isvacant() {
        require(currentStatus == Statuses.Vacant, "Currently Occupied.");
        _;
    }

    modifier cost(uint256 _amt) {
        require(msg.value >= _amt, "Not enough ether provided");
        _;
    }

    function bookHotel() public payable isvacant cost(2 ether) {
        address ownerAddress = msg.sender;
        currentStatus = Statuses.Occupied;
        bookings[ownerAddress] = Booking({
            owner: payable(msg.sender),
            checkedOut: false, // Set initial checkout status to false
            cancelled: false,
            amountPaid: msg.value // Initialize amountPaid to 0
        });
        // owner.transfer(msg.value);
        (
            bool send, /*bytes memory data*/

        ) = owner.call{value: msg.value}("");
        // require(true);
        if (send) {
            bookings[ownerAddress].amountPaid = msg.value; // Update amountPaid with the booking amount
            emit TransferSuccess(msg.sender, owner, msg.value);
        } else {
            emit TransferFailed(msg.sender, owner, msg.value);
            revert("Failed to transfer funds to the owner.");
        }
        emit Occupy(msg.sender, msg.value);
    }

    function cancelBooking() public {
        Booking storage booking = bookings[msg.sender];
        require(
            booking.owner == msg.sender,
            "You are not the owner of the booking."
        );
        require(!booking.checkedOut, "Cannot cancel a checked-out booking.");
        require(!booking.cancelled, "Booking is already cancelled.");

        uint256 amountToRefund = booking.amountPaid;
        require(amountToRefund > 0, "No refundable amount available.");

        booking.amountPaid = 0;
        booking.cancelled = true;

        address payable ownerPayable = payable(booking.owner);
        require(
            ownerPayable.send(amountToRefund),
            "Failed to refund the amount."
        );

        currentStatus = Statuses.Vacant;

        emit BookingCancelled(msg.sender, amountToRefund);
    }

    // function cancelBooking() public {
    //     address payable ownerAddress = msg.sender;
    //     Booking storage booking = bookings[ownerAddress];
    //     require(
    //         booking.owner == ownerAddress,
    //         "You are not the owner of the booking."
    //     );
    //     require(!booking.checkedOut, "Already checked Out or Cannot cancel a checked-out booking.");
    //     require(!booking.cancelled, "Booking is already cancelled.");
    //     uint256 amountToRefund = booking.amountPaid;
    //     booking.amountPaid = 0; // Reset the amountPaid to 0
    //     booking.cancelled = true; // Set the cancelled flag to true

    //     if(amountToRefund>0){

    //         uint256 contractBalance = address(this).balance;
    //     require(contractBalance >= amountToRefund, "Insufficient contract balance for refund");

    //     emit DebugLog("Contract balance before refund:", contractBalance);

    //         (bool send, /* bytes memory data */) = ownerAddress.call{value: amountToRefund}("");
    //         if (send){
    //             emit TransferSuccess(address(this), ownerAddress, amountToRefund);
    //         }else {
    //             booking.amountPaid = amountToRefund; // Restore the amountPaid in case refund fails
    //             booking.cancelled = false; // Reset the cancelled flag
    //             emit TransferFailed(address(this), booking.owner, amountToRefund);
    //             revert("Failed to refund the amount");
    //         }
    //     }

    //     emit BookingCancelled(msg.sender, amountToRefund);

    // }

    function getBookingDetails(address bookingAddress) public view returns ( address,bool,bool,uint256) {
        Booking storage booking = bookings[bookingAddress];
        return (
            booking.owner,
            booking.checkedOut,
            booking.cancelled,
            booking.amountPaid
        );
    }

    function checkout() public {
        require(currentStatus == Statuses.Occupied, "No Active Booking found.");
        Booking storage booking = bookings[msg.sender];
        require(
            booking.owner == msg.sender,
            "You are not the owner of the booking."
        );
        require(!booking.checkedOut, "Already checked Out.");

        booking.checkedOut = true;
        currentStatus = Statuses.Vacant;

        emit TransferSuccess(msg.sender, owner, 0);
    }
}

/*
Summary

Added the Booking struct with the owner and checkedOut fields to store the booking details.

Updated the bookings mapping to map the owner's address to the Booking struct.

Modified the bookHotel() function to assign a new Booking struct to the owner's address in the bookings mapping, setting the owner and checkedOut fields.

Updated the TransferFailed event to include the amount parameter, indicating the amount of funds that failed to be transferred.

Removed the unused data variable from the owner.call statement in the bookHotel() function.

Emit the TransferSuccess event in the checkout() function without the amount parameter since no funds are being transferred.
*/
