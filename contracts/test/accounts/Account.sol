// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IBasicFDT }    from "../../interfaces/IBasicFDT.sol";
import { IExtendedFDT } from "../../interfaces/IExtendedFDT.sol";


contract Account {


    /******************/
    /*** Basic FDT ***/
    /*****************/

    function try_basicFDT_updateFundsRecevied(address fdt) external returns(bool ok) {
        string memory sig = "updateFundsReceived()";
        (ok,) = fdt.call(abi.encodeWithSignature(sig));
    }

    function try_basicFDT_transfer(address fdt, address to, uint256 value) external returns(bool ok) {
        string memory sig = "transfer(address,uint256)";
        (ok,) = fdt.call(abi.encodeWithSignature(sig, to, value));
    }

    function basicFDT_recognizeLosses(address fdt) external {
        string memory sig = "recognizeLosses()";
        (bool ok,) = fdt.call(abi.encodeWithSignature(sig));
        require(ok);
    }

    function basicFDT_withdrawFunds(address fdt) external {
        IBasicFDT(fdt).withdrawFunds();
    }

    /*********************/
    /*** Extended FDT ***/
    /********************/

    function try_ExtendedFDT_updateLossesRecevied(address fdt) external returns(bool ok) {
        string memory sig = "updateLossesReceived()";
        (ok,) = fdt.call(abi.encodeWithSignature(sig));
    }

    function try_ExtendedFDT_transfer(address fdt, address to, uint256 value) external returns(bool ok) {
        string memory sig = "transfer(address,uint256)";
        (ok,) = fdt.call(abi.encodeWithSignature(sig, to, value));
    }

    function extendedFDT_withdrawFunds(address fdt) external {
        IExtendedFDT(fdt).withdrawFunds();
    }


    /***********************/
    /*** Basic Funds FDT ***/
    /**********************/

    function try_basicFundsTokenFDT_updateFundsRecevied(address fdt) external returns(bool ok) {
        string memory sig = "updateFundsReceived()";
        (ok,) = fdt.call(abi.encodeWithSignature(sig));
    }

    function try_basicFundsTokenFDT_transfer(address fdt, address to, uint256 value) external returns(bool ok) {
        string memory sig = "transfer(address,uint256)";
        (ok,) = fdt.call(abi.encodeWithSignature(sig, to, value));
    }

    function basicFundsTokenFDT_withdrawFunds(address fdt) external {
        IBasicFDT(fdt).withdrawFunds();
    }
}