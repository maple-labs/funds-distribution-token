pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./FundsDistributionToken.sol";

contract FundsDistributionTokenTest is DSTest {
    FundsDistributionToken token;

    function setUp() public {
        token = new FundsDistributionToken();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
