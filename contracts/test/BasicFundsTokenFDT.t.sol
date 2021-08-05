// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { MapleTest }        from "../../modules/maple-test/contracts/test.sol";
import { ERC20, SafeMath }  from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { BasicFundsTokenFDT } from "../BasicFundsTokenFDT.sol";
import { IBasicFDT }          from "../interfaces/IBasicFDT.sol";


contract CompleteBasicFundsTokenFDT is BasicFundsTokenFDT {

    constructor(string memory name, string memory symbol, address fundsToken) public BasicFundsTokenFDT(name, symbol, fundsToken) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

    function burn(address account, uint256 amt) public {
        _burn(account, amt);
    }

    function pointsCorrection_(address account) external view returns(int256) {
        return pointsCorrection[account];
    } 

    function pointsPerShare_() external view returns(uint256) {
        return pointsPerShare;
    }

    function pointsMultiplier_() external view returns(uint256) {
        return pointsMultiplier;
    }

}

contract MockToken is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

    function mint(address to, uint256 amt) public {
        _mint(to, amt);
    }

}

contract Account {

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

contract BasicFundsTokenFDTTest is MapleTest {

    using SafeMath for uint256;

    CompleteBasicFundsTokenFDT  fundsTokenFdt;
    MockToken                      fundsToken;
    Account                          account1;
    Account                          account2;

    function setUp() public {
        fundsToken    = new MockToken("Token", "TKN");
        fundsTokenFdt = new CompleteBasicFundsTokenFDT("BasicFDT", "FDT", address(fundsToken));
        account1      = new Account();
        account2      = new Account();
    }

    function test_updateFundsReceived() public {
        assertEq(fundsTokenFdt.fundsTokenBalance(), 0);
        // Mint and transfer some funds token to FundsTokenFDT.
        fundsToken.mint(address(fundsTokenFdt), 10000);

        assertTrue(!account1.try_basicFundsTokenFDT_updateFundsRecevied(address(fundsTokenFdt)));  // Should fail because total supply is zero
        
        fundsTokenFdt.mint(address(account1), 1000);
        fundsTokenFdt.mint(address(account2), 5000);

        assertEq(fundsTokenFdt.pointsPerShare_(), 0);  // Before the execution of `updateFundsReceived`.
        
        uint256 shouldBePointsPerCorrection = fundsTokenFdt.pointsPerShare_().add(uint256(10000).mul(fundsTokenFdt.pointsMultiplier_())/ fundsTokenFdt.totalSupply());
        assertTrue(account1.try_basicFundsTokenFDT_updateFundsRecevied(address(fundsTokenFdt)));  // Should pass as total supply is greater than 0.
        // Funds token balance get updated after the `updateFundsReceived()`.
        assertEq(fundsTokenFdt.fundsTokenBalance(),                       10000);
        assertEq(fundsTokenFdt.pointsPerShare_(),   shouldBePointsPerCorrection);

        shouldBePointsPerCorrection = fundsTokenFdt.pointsPerShare_().add(uint256(50000).mul(fundsTokenFdt.pointsMultiplier_())/ fundsTokenFdt.totalSupply());

        // Transfer more funds
        fundsToken.mint(address(fundsTokenFdt), 50000);
        fundsTokenFdt.updateFundsReceived();

        assertEq(fundsTokenFdt.fundsTokenBalance(),                       60000);
        assertEq(fundsTokenFdt.pointsPerShare_(),   shouldBePointsPerCorrection);
    }

    function test_mint() public {
        fundsTokenFdt.mint(address(account1), 1000);

        assertEq(fundsTokenFdt.balanceOf(address(account1)), 1000);
        assertEq(fundsTokenFdt.pointsCorrection_(address(account1)), 0);

        // Mint and transfer some funds token to FundsTokenFDT.
        fundsToken.mint(address(fundsTokenFdt), 10000);
        fundsTokenFdt.updateFundsReceived();

        // Mint more FDTs
        int256 newPointsCorrection = fundsTokenFdt.pointsCorrection_(address(account1)) - int256(fundsTokenFdt.pointsPerShare_().mul(2000));
        fundsTokenFdt.mint(address(account1), 2000);
        assertEq(fundsTokenFdt.balanceOf(address(account1)), 3000);
        assertEq(fundsTokenFdt.pointsCorrection_(address(account1)), newPointsCorrection);
    }

    function test_burn() public {
        fundsTokenFdt.mint(address(account1), 2000);
        fundsToken.mint(address(fundsTokenFdt), 10000);
        fundsTokenFdt.updateFundsReceived();
        int256 oldPointsCorrection = fundsTokenFdt.pointsCorrection_(address(account1));
        int256 newPointsCorrection = oldPointsCorrection + int256(fundsTokenFdt.pointsPerShare_().mul(100));
        // Mint and transfer some funds token to FundsTokenFDT.
        fundsTokenFdt.burn(address(account1), 100);

        assertEq(fundsTokenFdt.balanceOf(address(account1)), 1900);
        assertEq(fundsTokenFdt.pointsCorrection_(address(account1)), newPointsCorrection);
    }

    function test_transfer() public {
        fundsTokenFdt.mint(address(account1), 2000);
        fundsToken.mint(address(fundsTokenFdt), 10000);
        fundsTokenFdt.updateFundsReceived();

        int256 oldPointsCorrectionFrom = fundsTokenFdt.pointsCorrection_(address(account1));
        assertTrue(account1.try_basicFundsTokenFDT_transfer(address(fundsTokenFdt), address(account2), 500));
        int256 newPointsCorrectionFrom = fundsTokenFdt.pointsCorrection_(address(account1));

        int256 delta = newPointsCorrectionFrom - oldPointsCorrectionFrom;
        assertEq(fundsTokenFdt.pointsCorrection_(address(account2)), -delta);
    }

    function test_withdrawFunds() public {
        fundsTokenFdt.mint(address(account1), 2000);
        fundsTokenFdt.mint(address(account2), 3000);
        fundsToken.mint(address(fundsTokenFdt), 10000);
        fundsTokenFdt.updateFundsReceived();

        assertEq(fundsTokenFdt.withdrawnFundsOf(address(account1)), 0);
        assertEq(fundsTokenFdt.withdrawnFundsOf(address(account2)), 0);

        uint256 withdrawableFunds1 = fundsTokenFdt.withdrawableFundsOf(address(account1));
        uint256 withdrawableFunds2 = fundsTokenFdt.withdrawableFundsOf(address(account2));
        
        assertEq(fundsToken.balanceOf(address(account1)), 0);
        assertEq(fundsToken.balanceOf(address(account2)), 0);

        account1.basicFundsTokenFDT_withdrawFunds(address(fundsTokenFdt));
        account2.basicFundsTokenFDT_withdrawFunds(address(fundsTokenFdt));

        assertEq(fundsToken.balanceOf(address(account1)), withdrawableFunds1);
        assertEq(fundsToken.balanceOf(address(account2)), withdrawableFunds2);

        assertEq(fundsTokenFdt.withdrawnFundsOf(address(account1)), withdrawableFunds1);
        assertEq(fundsTokenFdt.withdrawnFundsOf(address(account2)), withdrawableFunds2);

        assertEq(fundsTokenFdt.withdrawableFundsOf(address(account1)), 0);
        assertEq(fundsTokenFdt.withdrawableFundsOf(address(account2)), 0);
    }

}
