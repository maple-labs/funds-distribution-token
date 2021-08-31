// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { ERC20 } from "../../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { BasicFundsTokenFDT } from "../../BasicFundsTokenFDT.sol";
import { BasicFDT }           from "../../BasicFDT.sol";
import { ExtendedFDT }        from "../../ExtendedFDT.sol";

import { ExtendedFDTUser } from "../accounts/ExtendedFDTUser.sol";

contract MockBasicFDT is BasicFDT {

    uint256 public fundsBalance;
    uint256 public lastFundsBalance;

    constructor(string memory name, string memory symbol) public BasicFDT(name, symbol) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function burn(address account, uint256 amt) public {
        _burn(account, amt);
    }

    function withdrawFunds() public virtual override {
        uint256 withdrawableFunds = _prepareWithdraw();
        fundsBalance              = fundsBalance.sub(withdrawableFunds);

        _updateFundsTokenBalance();
    }

    function _updateFundsTokenBalance() internal override returns (int256 delta) {
        delta            = int256(fundsBalance - lastFundsBalance);
        lastFundsBalance = fundsBalance;
    }

    function increaseFundsReceived(uint256 amount) external {
        fundsBalance = fundsBalance + amount;
    }

    function pointsCorrection_(address account) external view returns (int256) {
        return pointsCorrection[account];
    } 

    function pointsPerShare_() external view returns (uint256) {
        return pointsPerShare;
    }

    function pointsMultiplier_() external pure returns (uint256) {
        return pointsMultiplier;
    }

}

contract MockBasicFundsTokenFDT is BasicFundsTokenFDT {

    constructor(string memory name, string memory symbol, address fundsToken) public BasicFundsTokenFDT(name, symbol, fundsToken) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function burn(address account, uint256 amt) public {
        _burn(account, amt);
    }

    function pointsCorrection_(address account) external view returns (int256) {
        return pointsCorrection[account];
    } 

    function pointsPerShare_() external view returns (uint256) {
        return pointsPerShare;
    }

    function pointsMultiplier_() external pure returns (uint256) {
        return pointsMultiplier;
    }

}

contract MockExtendedFDT is ExtendedFDT {

    uint256 public fundsBalance;
    uint256 public lastFundsBalance;

    uint256 public lossesBalance;
    uint256 public lastLossesBalance;

    constructor(string memory name, string memory symbol) public ExtendedFDT(name, symbol) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function burn(address account, uint256 amt) public {
        _burn(account, amt);
    }
    
    function recognizeLosses() public {
        _recognizeLosses();
    }
 
    function _recognizeLosses() internal override returns (uint256 losses) {
        losses        = _prepareLossesWithdraw();
        lossesBalance = lossesBalance.sub(losses);

        _updateLossesBalance();
    }

    function _updateFundsTokenBalance() internal override returns (int256 delta) {
        delta            = int256(fundsBalance - lastFundsBalance);
        lastFundsBalance = fundsBalance;
    }

    function _updateLossesBalance() internal override returns (int256 delta) {
        delta             = int256(lossesBalance - lastLossesBalance);
        lastLossesBalance = lossesBalance;
    }

    function increaseLossesReceived(uint256 amount) external{
        lossesBalance = lossesBalance + amount;
    }

    function lossesCorrection_(address account) external view returns (int256) {
        return lossesCorrection[account];
    } 

    function lossesPerShare_() external view returns (uint256) {
        return lossesPerShare;
    }

    function pointsMultiplier_() external pure returns (uint256) {
        return pointsMultiplier;
    }

    function updateFundsReceived() public override virtual {
        int256 newFunds = _updateFundsTokenBalance();

        if (newFunds <= 0) return;

        _distributeFunds(newFunds.toUint256Safe());
    }

}

// recognizeLosses is not part of any fdt interface, so a custom mock user must be created for this mock implementation
contract MockExtendedFDTUser is ExtendedFDTUser {

    function fdt_mock_recognizeLosses(address fdt) external {
        MockExtendedFDT(fdt).recognizeLosses();
    }

}

contract MockToken is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

}
