// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IBasicFDT } from "../../interfaces/IBasicFDT.sol";

import { ERC20User } from "./ERC20User.sol";

contract BasicFDTUser is ERC20User {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function fdt_withdrawFunds(address fdt) external {
        IBasicFDT(fdt).withdrawFunds();
    }

    function fdt_updateFundsReceived(address fdt) external {
        IBasicFDT(fdt).updateFundsReceived();
    }

    /*********************/
    /*** Try functions ***/
    /*********************/

    function try_fdt_withdrawFunds(address fdt) external returns (bool ok) {
        (ok,) = fdt.call(abi.encodeWithSelector(IBasicFDT.withdrawFunds.selector));
    }

    function try_fdt_updateFundsReceived(address fdt) external returns (bool ok) {
        (ok,) = fdt.call(abi.encodeWithSelector(IBasicFDT.updateFundsReceived.selector));
    }

}
