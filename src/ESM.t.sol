pragma solidity ^0.5.6;

import "ds-test/test.sol";
import "ds-token/token.sol";

// this dependency is only here for FV
import "dss/end.sol";

import "./ESM.sol";

contract EndMock {
    uint256 public live;

    constructor()   public { live = 1; }
    function cage() public { live = 0; }
}

contract TestUsr {
    DSToken gem;

    constructor(DSToken gem_) public {
        gem = gem_;
    }
    function callJoin(ESM esm, uint256 wad) external {
        gem.approve(address(esm), uint256(-1));

        esm.join(wad);
    }
}

contract ESMTest is DSTest {
    ESM     esm;
    DSToken gem;
    EndMock end;
    uint256 min;
    address pit;
    TestUsr usr;
    TestUsr gov;

    function setUp() public {
        gem = new DSToken("GOLD");
        end = new EndMock();
        usr = new TestUsr(gem);
        gov = new TestUsr(gem);
        pit = address(0x42);
    }

    function test_constructor() public {
        esm = makeWithCap(10);

        assertEq(address(esm.gem()), address(gem));
        assertEq(address(esm.end()), address(end));
        assertEq(esm.min(), 10);
        assertEq(esm.fired(), 0);
    }

    function test_Sum_is_internal_balance() public {
        esm = makeWithCap(10);
        gem.mint(address(esm), 10);

        assertEq(esm.Sum(), 0);
    }

    function test_fire() public {
        esm = makeWithCap(0);
        esm.fire();

        assertEq(esm.fired(), 1);
        assertEq(end.live(), 0);
    }

    function testFail_fire_twice() public {
        esm = makeWithCap(0);
        esm.fire();

        esm.fire();
    }

    function testFail_join_after_fired() public {
        esm = makeWithCap(0);
        esm.fire();
        gem.mint(address(usr), 10);

        usr.callJoin(esm, 10);
    }

    function testFail_fire_min_not_met() public {
        esm = makeWithCap(10);
        assertTrue(esm.Sum() <= esm.min());

        esm.fire();
    }

    // -- user actions --
    function test_join() public {
        gem.mint(address(usr), 10);
        esm = makeWithCap(10);

        usr.callJoin(esm, 10);

        assertEq(esm.Sum(), 10);
        assertEq(gem.balanceOf(address(esm)), 0);
        assertEq(gem.balanceOf(address(usr)), 0);
        assertEq(gem.balanceOf(address(pit)), 10);
    }

    function test_join_over_min() public {
        gem.mint(address(usr), 20);
        esm = makeWithCap(10);

        usr.callJoin(esm, 10);
        usr.callJoin(esm, 10);
    }

    function testFail_join_insufficient_balance() public {
        assertEq(gem.balanceOf(address(usr)), 0);

        usr.callJoin(esm, 10);
    }

    // -- internal test helpers --
    function makeWithCap(uint256 min_) internal returns (ESM) {
        return new ESM(address(gem), address(end), pit, min_);
    }
}
