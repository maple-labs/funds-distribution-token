// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IERC20, SafeERC20 } from "../modules/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol";

import { IBasicFundsTokenFDT } from "./interfaces/IBasicFundsTokenFDT.sol";

import { BasicFDT } from "./BasicFDT.sol";

/// @title BasicFundsTokenFDT implements the Basic FDT functionality with a separate Funds Token.
abstract contract BasicFundsTokenFDT is IBasicFundsTokenFDT, BasicFDT {

    using SafeERC20 for IERC20;

    address public override immutable fundsToken;

    uint256 public override fundsTokenBalance;

    constructor(string memory name, string memory symbol, address _fundsToken) BasicFDT(name, symbol) public {
        fundsToken = _fundsToken;
    }

    function withdrawFunds() public virtual override(IBasicFundsTokenFDT, BasicFDT) {
        uint256 withdrawableFunds = _prepareWithdraw();

        if (withdrawableFunds > uint256(0)) {
            IERC20(fundsToken).safeTransfer(msg.sender, withdrawableFunds);

            _updateFundsTokenBalance();
        }
    }

    /**
        @dev    Updates the current `fundsToken` balance and returns the difference of the new and previous `fundsToken` balance.
        @return A int256 representing the difference of the new and previous `fundsToken` balance.
     */
    function _updateFundsTokenBalance() internal virtual override returns (int256) {
        uint256 _prevFundsTokenBalance = fundsTokenBalance;

        fundsTokenBalance = IERC20(fundsToken).balanceOf(address(this));

        return int256(fundsTokenBalance).sub(int256(_prevFundsTokenBalance));
    }

}
