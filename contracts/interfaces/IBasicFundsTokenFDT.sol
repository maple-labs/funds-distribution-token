// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IBasicFDT } from "./IBasicFDT.sol";

/// @title BasicFundsTokenFDT implements the Basic FDT functionality with a separate Funds Token.
interface IBasicFundsTokenFDT is IBasicFDT {

    /**
        @dev The `fundsToken` (dividends).
     */
    function fundsToken() external view returns (address);

    /**
        @dev The amount of `fundsToken` currently present and accounted for in this contract.
     */
    function fundsTokenBalance() external view returns (uint256);

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds() external override;

}
