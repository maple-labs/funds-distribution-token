// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IExtendedFDT } from "../../interfaces/IExtendedFDT.sol";

import { BasicFDTUser } from "./BasicFDTUser.sol";

contract ExtendedFDTUser is BasicFDTUser {

    /************************/
    /*** Direct Functions ***/
    /***********************/

    function fdt_updateLossesReceived(address fdt) external {
        IExtendedFDT(fdt).updateLossesReceived();
    }

    /**********************/
    /*** Try functions ***/
    /********************/

    function try_fdt_updateLossesReceived(address fdt) external returns (bool ok) {
        (ok,) = fdt.call(abi.encodeWithSelector(IExtendedFDT.updateLossesReceived.selector));
    }

}
