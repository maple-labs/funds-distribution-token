// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { MapleTest } from "../../modules/maple-test/contracts/test.sol";

import { BasicFDTUser } from "./accounts/BasicFDTUser.sol";

import { MockBasicFDT } from "./mocks/Mocks.sol";

contract BasicFDTTest is MapleTest {

    BasicFDTUser account1;
    BasicFDTUser account2;
    MockBasicFDT token;

    function setUp() public {
        account1 = new BasicFDTUser();
        account2 = new BasicFDTUser();
        token    = new MockBasicFDT("MockFDT", "FDT");
    }

    function test_updateFundsReceived() public {
        assertEq(token.fundsBalance(), 0);

        token.increaseFundsReceived(10_000);

        assertTrue(!account1.try_fdt_updateFundsReceived(address(token)));  // Should fail because total supply is zero
        
        token.mint(address(account1), 1000);
        token.mint(address(account2), 5000);

        assertEq(token.pointsPerShare_(), 0);  // Before the execution of `updateFundsReceived`.
        
        assertTrue(account1.try_fdt_updateFundsReceived(address(token)));  // Should pass as total supply is greater than 0.
        
        assertEq(token.fundsBalance(),    10_000);
        assertEq(token.pointsPerShare_(), 567137278201564105772291012386280352426); // pointsPerShare + 10_000 * pointMultiplier / totalSupply

        token.increaseFundsReceived(50_000);
        token.updateFundsReceived();

        assertEq(token.fundsBalance(),    60_000);
        assertEq(token.pointsPerShare_(), 3402823669209384634633746074317682114559); // pointsPerShare + 50_000 * pointMultiplier / totalSupply
    }

    function test_mint() public {
        token.mint(address(account1), 1000);

        assertEq(token.balanceOf(address(account1)),         1000);
        assertEq(token.pointsCorrection_(address(account1)), 0);

        token.increaseFundsReceived(10_000);
        token.updateFundsReceived();

        token.mint(address(account1), 2000);

        assertEq(token.balanceOf(address(account1)),         3000);
        assertEq(token.pointsCorrection_(address(account1)), -6805647338418769269267492148635364229120000); // pointsCorrection[account1] - 2000 * pointMultiplier
    }

    function test_burn() public {
        token.mint(address(account1), 2000);
        token.increaseFundsReceived(10_000);
        token.updateFundsReceived();

        int256 oldPointsCorrection = token.pointsCorrection_(address(account1));
        int256 newPointsCorrection = oldPointsCorrection + int256(token.pointsPerShare_() * 100);

        token.burn(address(account1), 100);

        assertEq(token.balanceOf(address(account1)),         1900);
        assertEq(token.pointsCorrection_(address(account1)), newPointsCorrection);
    }

    function test_transfer() public {
        token.mint(address(account1), 2000);
        token.increaseFundsReceived(10_000);
        token.updateFundsReceived();

        int256 oldPointsCorrectionFrom = token.pointsCorrection_(address(account1));
        assertTrue(account1.try_erc20_transfer(address(token), address(account2), 500));
        int256 newPointsCorrectionFrom = token.pointsCorrection_(address(account1));

        int256 delta = newPointsCorrectionFrom - oldPointsCorrectionFrom;
        assertEq(token.pointsCorrection_(address(account2)), -delta);
    }

    function test_withdrawFunds() public {
        token.mint(address(account1), 2000);
        token.mint(address(account2), 3000);
        token.increaseFundsReceived(10_000);
        token.updateFundsReceived();

        assertEq(token.withdrawnFundsOf(address(account1)), 0);
        assertEq(token.withdrawnFundsOf(address(account2)), 0);

        uint256 withdrawableFunds1 = token.withdrawableFundsOf(address(account1));
        uint256 withdrawableFunds2 = token.withdrawableFundsOf(address(account2));

        assertEq(withdrawableFunds1, 4000);
        assertEq(withdrawableFunds2, 6000);
        
        account1.fdt_withdrawFunds(address(token));
        account2.fdt_withdrawFunds(address(token));

        assertEq(token.withdrawnFundsOf(address(account1)), withdrawableFunds1);
        assertEq(token.withdrawnFundsOf(address(account2)), withdrawableFunds2);

        assertEq(token.withdrawableFundsOf(address(account1)), 0);
        assertEq(token.withdrawableFundsOf(address(account2)), 0);
    }

}
