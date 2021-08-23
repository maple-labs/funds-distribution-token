// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { MapleTest }        from "../../modules/maple-test/contracts/test.sol";
import { ERC20, SafeMath }  from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { ExtendedFDT } from "../ExtendedFDT.sol";

import { IExtendedFDT } from "../interfaces/IExtendedFDT.sol";

import { Account } from "./accounts/Account.sol";

contract MockFDT is ExtendedFDT {

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

contract ExtendedFDTTest is MapleTest {

    Account   account1;
    Account   account2;
    MockFDT   token;

    function setUp() public {
        account1 = new Account();
        account2 = new Account();
        token    = new MockFDT("MockFDT", "FDT");
    }

    function test_updateLossesReceived() public {
        assertEq(token.lossesBalance(), 0);

        token.increaseLossesReceived(10_000);

        assertTrue(!account1.try_extendedFDT_updateLossesRecevied(address(token)));  // Should fail because total supply is zero
        
        token.mint(address(account1), 1000);
        token.mint(address(account2), 5000);

        assertEq(token.lossesPerShare_(), 0);  // Before the execution of `updateLossesReceived`.
        
        assertTrue(account1.try_extendedFDT_updateLossesRecevied(address(token)));  // Should pass as total supply is greater than 0.

        assertEq(token.lossesBalance(),   10_000);
        assertEq(token.lossesPerShare_(), 567137278201564105772291012386280352426); // lossesPerShare + 10_000 * pointMultiplier / totalSupply

        token.increaseLossesReceived(50_000);
        token.updateLossesReceived();

        assertEq(token.lossesBalance(),   60_000);
        assertEq(token.lossesPerShare_(), 3402823669209384634633746074317682114559); // lossessPerShare + 50_000 * pointMultiplier / totalSupply
    }

    function test_mint() public {
        token.mint(address(account1), 1000);

        assertEq(token.balanceOf(address(account1)),         1000);
        assertEq(token.lossesCorrection_(address(account1)), 0);

        token.increaseLossesReceived(10_000);
        token.updateLossesReceived();

        token.mint(address(account1), 2000);

        assertEq(token.balanceOf(address(account1)),         3000);
        assertEq(token.lossesCorrection_(address(account1)), -6805647338418769269267492148635364229120000); // lossesCorrection[account1] - 2000 * pointMultiplier
    }

    function test_burn() public {
        token.mint(address(account1), 2000);
        token.increaseLossesReceived(10_000);
        token.updateLossesReceived();

        int256 oldLossesCorrection = token.lossesCorrection_(address(account1));
        int256 newLossesCorrection = oldLossesCorrection + int256(token.lossesPerShare_() * 100);
        
        token.burn(address(account1), 100);

        assertEq(token.balanceOf(address(account1)),         1900);
        assertEq(token.lossesCorrection_(address(account1)), newLossesCorrection);
    }

    function test_transfer() public {
        token.mint(address(account1), 2000);
        token.increaseLossesReceived(10_000);
        token.updateLossesReceived();

        int256 oldLossesCorrectionFrom = token.lossesCorrection_(address(account1));
        assertTrue(account1.try_extendedFDT_transfer(address(token), address(account2), 500));
        int256 newLossesCorrectionFrom = token.lossesCorrection_(address(account1));

        int256 delta = newLossesCorrectionFrom - oldLossesCorrectionFrom;
        assertEq(token.lossesCorrection_(address(account2)), -delta);
    }

    function test_recognizeLosses() public {
        token.mint(address(account1), 2000);
        token.mint(address(account2), 3000);
        token.increaseLossesReceived(10_000);
        token.updateLossesReceived();

        assertEq(token.recognizedLossesOf(address(account1)), 0);
        assertEq(token.recognizedLossesOf(address(account2)), 0);

        uint256 recognizableLossesOf1 = token.recognizableLossesOf(address(account1));
        uint256 recognizableLossesOf2 = token.recognizableLossesOf(address(account2));

        assertEq(recognizableLossesOf1, 4000);
        assertEq(recognizableLossesOf2, 6000);
        
        account1.basicFDT_recognizeLosses(address(token));
        account2.basicFDT_recognizeLosses(address(token));

        assertEq(token.recognizedLossesOf(address(account1)), recognizableLossesOf1);
        assertEq(token.recognizedLossesOf(address(account2)), recognizableLossesOf2);

        assertEq(token.recognizableLossesOf(address(account1)), 0);
        assertEq(token.recognizableLossesOf(address(account2)), 0);
    }

}
