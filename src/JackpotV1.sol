// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract JackpotV1 {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       CONSTANTS                                           //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public constant TICKET_PRICE = 0.0055 ether;
    uint256 public constant OWNER_FEE_PERCENT = 10;
    uint256 public constant DRAW_INTERVAL = 1 weeks;
    uint256 public constant TICKET_PRICE_ETH = 0.00055 ether; // on development time is 2$

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                        State Variable                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public s_ownerBalance;
    address public s_developer;

    struct Ticket {
        uint8[5] whiteNumbers;
        uint8 redNumber;
        address buyer;
    }

    struct Draw {
        uint256 totalPot;
        uint8[5] winningWhiteNumbers;
        uint8 winningRedNumber;
        bool isJackpotWeek;
        bool drawn;
        uint256 drawEndTime;
        mapping(address => Ticket[]) tickets;
        Ticket[] allTickets;
        mapping(address => bool) claimed;
    }

    Draw[] public draws;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                        Events                                             //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    event TicketPurchased(uint256 indexed drawIndex, address indexed buyer, uint256 value);
    event DrawExecuted(uint256 indexed drawIndex, uint8[5] winningWhiteNumbers, uint8 winningRedNumber);
    event ClaimPrize(uint256 indexed drawIndex, address indexed claimer, uint256 prize);

    event WithdrawFees(uint256 indexed amount);
    event ChangeDeveloper(address indexed oldDeveloper, address indexed newDeveloper);

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                        Errors                                             //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    error BuyTicketNotEnough();
    error OnlyDeveloper();
    error ZeroAddress();
    error TransferFailed();
    error MismatchedInputLengths();
    error IncorrectTotalTicketPrice();
    error WhiteNumbersMustBeBetween1And69();
    error RedNumberMustBeBetween1And26();
    error DrawIntervalNotPassed();
    error DrawFreezeTimePassed();
    error DrawAlreadyExecuted();
    error DrawNotExecuted();
    error PrizeAlreadyClaimed();
    error NoPrizeForTicket();

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                    CONSTRUCTOR                                            //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    constructor(uint256 initialTimestamp) {
        s_developer = msg.sender;
        draws.push(); // Initialize the first draw
        draws[0].drawEndTime = initialTimestamp; // Set the end timestamp for the first draw
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                    Public functions                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Buys one or more tickets for the current draw.
    /// @param whiteNumbersArray An array of arrays, each containing 5 white numbers.
    /// @param redNumbers An array containing the red number for each ticket.
    function buyTicket(uint8[5][] memory whiteNumbersArray, uint8[] memory redNumbers) public payable {
        if (whiteNumbersArray.length != redNumbers.length) revert MismatchedInputLengths();
        uint256 totalCost = TICKET_PRICE * whiteNumbersArray.length;
        if (msg.value != totalCost) revert IncorrectTotalTicketPrice();

        Draw storage draw = draws[draws.length - 1];

        // Check if less than one hour is left for the draw
        if (block.timestamp >= (draw.drawEndTime - 1 hours)) {
            revert DrawFreezeTimePassed();
        }

        for (uint256 j = 0; j < whiteNumbersArray.length; j++) {
            uint8[5] memory whiteNumbers = whiteNumbersArray[j];
            uint8 redNumber = redNumbers[j];

            for (uint8 i = 0; i < 5; i++) {
                if (whiteNumbers[i] < 1 || whiteNumbers[i] > 69) revert WhiteNumbersMustBeBetween1And69();
            }
            if (redNumber < 1 || redNumber > 26) revert RedNumberMustBeBetween1And26();

            Ticket memory newTicket = Ticket({whiteNumbers: whiteNumbers, redNumber: redNumber, buyer: msg.sender});
            draw.tickets[msg.sender].push(newTicket);
            draw.allTickets.push(newTicket);
        }

        uint256 ownerFee = (msg.value * OWNER_FEE_PERCENT) / 100;
        s_ownerBalance += ownerFee;

        emit TicketPurchased(draws.length - 1, msg.sender, msg.value);
    }

    /// @notice Executes the current draw and sets up the next draw.
    function executeDraw() public {
        uint256 currentTime = block.timestamp;
        Draw storage draw = draws[draws.length - 1];

        // Check if draw interval has passed since drawEndTime
        require(currentTime >= draw.drawEndTime, DrawIntervalNotPassed());

        // not possible but we check it
        require(!draw.drawn, DrawAlreadyExecuted());

        uint8[5] memory winningWhiteNumbers;
        for (uint8 i = 0; i < 5; i++) {
            winningWhiteNumbers[i] = random(69, i);
        }
        uint8 winningRedNumber = random(26, 5);

        draw.winningWhiteNumbers = winningWhiteNumbers;
        draw.winningRedNumber = winningRedNumber;
        draw.drawn = true;

        draw.isJackpotWeek = determineJackpotWeek();

        uint256 availableBalance = address(this).balance - s_ownerBalance;
        if (draw.isJackpotWeek) {
            draw.totalPot = (availableBalance * 70) / 100;
        } else {
            draw.totalPot = (availableBalance * 10) / 100;
        }

        draws.push(); // Initialize the next draw
        Draw storage nextDraw = draws[draws.length - 1];

        // Calculate next draw end time
        nextDraw.drawEndTime = draw.drawEndTime + DRAW_INTERVAL;
        while (nextDraw.drawEndTime <= currentTime) {
            nextDraw.drawEndTime += DRAW_INTERVAL;
        }

        nextDraw.totalPot = availableBalance - draw.totalPot;

        emit DrawExecuted(draws.length - 1, winningWhiteNumbers, winningRedNumber);
    }

    /// @notice Claims the prize for a specific draw.
    /// @param drawIndex The index of the draw to claim the prize from.
    function claimPrize(uint256 drawIndex) public {
        Draw storage draw = draws[drawIndex];
        require(draw.drawn, DrawNotExecuted());
        require(!draw.claimed[msg.sender], PrizeAlreadyClaimed());

        uint256 prize = calculatePrize(draw, msg.sender);
        require(prize > 0, NoPrizeForTicket());

        draw.claimed[msg.sender] = true;
        payable(msg.sender).transfer(prize);
        emit ClaimPrize(drawIndex, msg.sender, prize);
    }

    /// @notice Withdraws the fees collected by the owner.
    function withdrawFees() external {
        require(msg.sender == s_developer, OnlyDeveloper());
        uint256 amount = s_ownerBalance;
        s_ownerBalance = 0;
        (bool success,) = s_developer.call{value: amount}("");
        if (!success) revert TransferFailed();
        emit WithdrawFees(amount);
    }

    function changeDeveloper(address newDeveloper) external {
        require(msg.sender == s_developer, OnlyDeveloper());
        require(newDeveloper != address(0), ZeroAddress());
        emit ChangeDeveloper(s_developer, newDeveloper);
        s_developer = newDeveloper;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                        View functions                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the current draw index.
    /// @return The index of the current draw.
    function getCurrentDrawIndex() public view returns (uint256) {
        return draws.length - 1;
    }

    /// @notice Returns the total number of draws.
    /// @return The total number of draws.
    function getTotalDraws() public view returns (uint256) {
        return draws.length;
    }

    /// @notice Returns the timestamp of when a draw was executed.
    /// @param drawIndex The index of the draw.
    /// @return The timestamp of when the draw was executed.
    function getDrawTimestamp(uint256 drawIndex) public view returns (uint256) {
        return draws[drawIndex].drawEndTime;
    }

    /// @notice Returns the total pot for a specific draw.
    /// @param drawIndex The index of the draw.
    /// @return The total pot for the specified draw.
    function getDrawTotalPot(uint256 drawIndex) public view returns (uint256) {
        return draws[drawIndex].totalPot;
    }

    /// @notice Returns whether a draw is a jackpot week.
    /// @param drawIndex The index of the draw.
    /// @return Whether the specified draw is a jackpot week.
    function isJackpotWeek(uint256 drawIndex) public view returns (bool) {
        return draws[drawIndex].isJackpotWeek;
    }

    /// @notice Returns the winning white numbers for a specific draw.
    /// @param drawIndex The index of the draw.
    /// @return The winning white numbers for the specified draw.
    function getWinningWhiteNumbers(uint256 drawIndex) public view returns (uint8[5] memory) {
        return draws[drawIndex].winningWhiteNumbers;
    }

    /// @notice Returns the winning red number for a specific draw.
    /// @param drawIndex The index of the draw.
    /// @return The winning red number for the specified draw.
    function getWinningRedNumber(uint256 drawIndex) public view returns (uint8) {
        return draws[drawIndex].winningRedNumber;
    }

    /// @notice Returns the tickets purchased by a specific address for a specific draw.
    /// @param drawIndex The index of the draw.
    /// @param buyer The address of the buyer.
    /// @return An array of tickets purchased by the specified address for the specified draw.
    function getTicketsByAddress(uint256 drawIndex, address buyer) public view returns (Ticket[] memory) {
        return draws[drawIndex].tickets[buyer];
    }

    /// @notice Returns whether a prize has been claimed by a specific address for a specific draw.
    /// @param drawIndex The index of the draw.
    /// @param claimant The address of the claimant.
    /// @return Whether the prize has been claimed by the specified address for the specified draw.
    function hasClaimedPrize(uint256 drawIndex, address claimant) public view returns (bool) {
        return draws[drawIndex].claimed[claimant];
    }

    /// @notice Returns the owner's balance.
    /// @return The owner's balance.
    function getOwnerBalance() public view returns (uint256) {
        return s_ownerBalance;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                        Internal functions                                 //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Determines if the current draw is a jackpot week.
    /// @return Whether the current draw is a jackpot week.
    function determineJackpotWeek() private view returns (bool) {
        if (draws.length < 5) {
            return false;
        }

        for (uint256 i = draws.length - 1; i >= draws.length - 4; i--) {
            if (draws[i].isJackpotWeek) {
                return false;
            }
        }

        return true;
    }

    /// @notice Generates a random number within a specified range.
    /// @param max The maximum value for the random number.
    /// @param salt A salt value for generating the random number.
    /// @return A random number within the specified range.
    function random(uint8 max, uint8 salt) private view returns (uint8) {
        return uint8(
            uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, salt))) % max
                + 1
        );
    }

    /// @notice Calculates the prize for a specific address for a specific draw.
    /// @param draw The draw data.
    /// @param claimer The address of the claimer.
    /// @return The prize amount.
    function calculatePrize(Draw storage draw, address claimer) private view returns (uint256) {
        uint256[8] memory winnersCount;

        // Iterate through all tickets to count the winners
        uint256 allTicketsLength = draw.allTickets.length;
        for (uint256 i = 0; i < allTicketsLength; i++) {
            Ticket storage ticket = draw.allTickets[i];
            uint8 matchingWhiteNumbers = countMatchingWhiteNumbers(draw.winningWhiteNumbers, ticket.whiteNumbers);
            bool matchingRedNumber = (draw.winningRedNumber == ticket.redNumber);

            if (matchingWhiteNumbers == 5 && matchingRedNumber) {
                winnersCount[0]++; // Jackpot
            } else if (matchingWhiteNumbers == 5) {
                winnersCount[1]++; // Match 5
            } else if (matchingWhiteNumbers == 4 && matchingRedNumber) {
                winnersCount[2]++; // Match 4 + Red
            } else if (matchingWhiteNumbers == 4) {
                winnersCount[3]++; // Match 4
            } else if (matchingWhiteNumbers == 3 && matchingRedNumber) {
                winnersCount[4]++; // Match 3 + Red
            } else if (matchingWhiteNumbers == 3) {
                winnersCount[5]++; // Match 3
            } else if (matchingWhiteNumbers == 2 && matchingRedNumber) {
                winnersCount[6]++; // Match 2 + Red
            } else if (matchingRedNumber) {
                winnersCount[7]++; // Match Red
            }
        }

        uint256 prize = 0;
        Ticket[] storage tickets = draw.tickets[claimer];

        for (uint256 i = 0; i < tickets.length; i++) {
            Ticket storage ticket = tickets[i];
            uint8 matchingWhiteNumbers = countMatchingWhiteNumbers(draw.winningWhiteNumbers, ticket.whiteNumbers);
            bool matchingRedNumber = (draw.winningRedNumber == ticket.redNumber);

            if (matchingWhiteNumbers == 5 && matchingRedNumber) {
                prize += (draw.totalPot * 75) / (100 * winnersCount[0]); // 75% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 5) {
                prize += (draw.totalPot * 10) / (100 * winnersCount[1]); // 10% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 4 && matchingRedNumber) {
                prize += (draw.totalPot * 5) / (100 * winnersCount[2]); // 5% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 4) {
                prize += (draw.totalPot * 25) / (1000 * winnersCount[3]); // 2.5% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 3 && matchingRedNumber) {
                prize += (draw.totalPot * 1) / (100 * winnersCount[4]); // 1% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 3) {
                prize += (draw.totalPot * 5) / (1000 * winnersCount[5]); // 0.5% of the total pot divided by the number of winners
            } else if (matchingWhiteNumbers == 2 && matchingRedNumber) {
                prize += (draw.totalPot * 25) / (10000 * winnersCount[6]); // 0.25% of the total pot divided by the number of winners
            } else if (matchingRedNumber) {
                prize += (draw.totalPot * 1) / (1000 * winnersCount[7]); // 0.1% of the total pot divided by the number of winners
            }
        }

        return prize;
    }

    /// @notice Counts the number of matching white numbers between the winning numbers and the ticket numbers.
    /// @param winningNumbers The winning white numbers.
    /// @param ticketNumbers The ticket's white numbers.
    /// @return The number of matching white numbers.
    function countMatchingWhiteNumbers(uint8[5] memory winningNumbers, uint8[5] memory ticketNumbers)
        private
        pure
        returns (uint8)
    {
        uint8 count = 0;
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = 0; j < 5; j++) {
                if (ticketNumbers[i] == winningNumbers[j]) {
                    count++;
                    break;
                }
            }
        }
        return count;
    }
}
