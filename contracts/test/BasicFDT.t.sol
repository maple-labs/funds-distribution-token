// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { MapleTest }        from "../../modules/maple-test/contracts/test.sol";
import { ERC20, SafeMath }  from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { BasicFDT }         from "../BasicFDT.sol";
import { IBasicFDT }        from "../interfaces/IBasicFDT.sol";

import { Account }          from "./accounts/Account.sol";


contract MockFDT is BasicFDT {

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
        fundsBalance = fundsBalance.sub(withdrawableFunds);
        _updateFundsTokenBalance();
    }

    function _updateFundsTokenBalance() internal override returns (int256 delta) {
        delta = int256(fundsBalance - lastFundsBalance);
        lastFundsBalance = fundsBalance;
    }

    function increaseFundsReceived(uint256 amount) external{
        fundsBalance = fundsBalance + amount;
    }

     function pointsCorrection_(address account) external view returns(int256) {
        return pointsCorrection[account];
    } 

    function pointsPerShare_() external view returns(uint256) {
        return pointsPerShare;
    }

    function pointsMultiplier_() external pure returns(uint256) {
        return pointsMultiplier;
    }
}

contract BasicFDTTest is MapleTest {

    using SafeMath for uint256;

    MockFDT   token;
    Account       account1;
    Account       account2;

    function setUp() public {
        token    = new MockFDT("MockFDT", "FDT");
        account1 = new Account();
        account2 = new Account();
    }

    function test_updateFundsReceived() public {
        assertEq(token.fundsBalance(), 0);
        // Mint and transfer some funds token to FundsTokenFDT.
        token.increaseFundsReceived(10000);

        assertTrue(!account1.try_basicFDT_updateFundsRecevied(address(token)));  // Should fail because total supply is zero
        
        token.mint(address(account1), 1000);
        token.mint(address(account2), 5000);

        assertEq(token.pointsPerShare_(), 0);  // Before the execution of `updateFundsReceived`.
        
        uint256 shouldBePointsPerCorrection = token.pointsPerShare_().add(uint256(10000).mul(token.pointsMultiplier_())/ token.totalSupply());
        assertTrue(account1.try_basicFDT_updateFundsRecevied(address(token)));  // Should pass as total supply is greater than 0.
        // Funds token balance get updated after the `updateFundsReceived()`.
        assertEq(token.fundsBalance(),                            10000);
        assertEq(token.pointsPerShare_(),   shouldBePointsPerCorrection);

        shouldBePointsPerCorrection = token.pointsPerShare_().add(uint256(50000).mul(token.pointsMultiplier_())/ token.totalSupply());

        // Transfer more funds
        token.increaseFundsReceived(50000);
        token.updateFundsReceived();

        assertEq(token.fundsBalance(),                       60000);
        assertEq(token.pointsPerShare_(),   shouldBePointsPerCorrection);
    }

    function test_mint() public {
        token.mint(address(account1), 1000);

        assertEq(token.balanceOf(address(account1)), 1000);
        assertEq(token.pointsCorrection_(address(account1)), 0);

        // Mint and transfer some funds token to token.
        token.increaseFundsReceived(10000);
        token.updateFundsReceived();

        // Mint more FDTs
        int256 newPointsCorrection = token.pointsCorrection_(address(account1)) - int256(token.pointsPerShare_().mul(2000));
        token.mint(address(account1), 2000);
        assertEq(token.balanceOf(address(account1)), 3000);
        assertEq(token.pointsCorrection_(address(account1)), newPointsCorrection);
    }

    function test_burn() public {
        token.mint(address(account1), 2000);
        token.increaseFundsReceived(10000);
        token.updateFundsReceived();
        int256 oldPointsCorrection = token.pointsCorrection_(address(account1));
        int256 newPointsCorrection = oldPointsCorrection + int256(token.pointsPerShare_().mul(100));
        // Mint and transfer some funds token to token.
        token.burn(address(account1), 100);

        assertEq(token.balanceOf(address(account1)), 1900);
        assertEq(token.pointsCorrection_(address(account1)), newPointsCorrection);
    }

    function test_transfer() public {
        token.mint(address(account1), 2000);
        token.increaseFundsReceived(10000);
        token.updateFundsReceived();

        int256 oldPointsCorrectionFrom = token.pointsCorrection_(address(account1));
        assertTrue(account1.try_basicFDT_transfer(address(token), address(account2), 500));
        int256 newPointsCorrectionFrom = token.pointsCorrection_(address(account1));

        int256 delta = newPointsCorrectionFrom - oldPointsCorrectionFrom;
        assertEq(token.pointsCorrection_(address(account2)), -delta);
    }

    function test_withdrawFunds() public {
        token.mint(address(account1), 2000);
        token.mint(address(account2), 3000);
        token.increaseFundsReceived(10000);
        token.updateFundsReceived();

        assertEq(token.withdrawnFundsOf(address(account1)), 0);
        assertEq(token.withdrawnFundsOf(address(account2)), 0);

        uint256 withdrawableFunds1 = token.withdrawableFundsOf(address(account1));
        uint256 withdrawableFunds2 = token.withdrawableFundsOf(address(account2));
        
        account1.basicFDT_withdrawFunds(address(token));
        account2.basicFDT_withdrawFunds(address(token));

        assertEq(token.withdrawnFundsOf(address(account1)), withdrawableFunds1);
        assertEq(token.withdrawnFundsOf(address(account2)), withdrawableFunds2);

        assertEq(token.withdrawableFundsOf(address(account1)), 0);
        assertEq(token.withdrawableFundsOf(address(account2)), 0);
    }

}
