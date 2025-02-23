// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../TokenConversion.sol";

contract TokenConversionTest is Test {
    TokenConversion private conversion;
    address private owner;
    IERC20 public fdt = IERC20(0xEd1480d12bE41d92F36f5f7bDd88212E381A3677);
    IERC20 public bond = IERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);
    uint256 public rate = 750; // the amount of TOKENIN that converts to 1 WAD of TOKENOUT
    uint256 public duration = 365 days; // the vesting duration (1 year)
    uint256 public expiration = 1706831999; // expiration of conversion (2024-02-01 23:59:59 GMT+0000)

    function setUp() public {
        // set up conversion contract
        owner = address(this);
        conversion = new TokenConversion(
            address(fdt),
            address(bond),
            rate,
            duration,
            expiration,
            owner
        );
        deal(address(bond), address(conversion), 1000 ether);

        // set up testing account with fdt
        deal(address(fdt), address(this), 10000000 ether);
        fdt.approve(address(conversion), type(uint256).max);
    }

    function test_CanChangeOwner() public {
        conversion.transferOwnership(address(0x2));
        assertEq(conversion.owner(), address(0x2));
    }

    function test_OtherUsersCannotChangeOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert("Ownable: caller is not the owner");
        conversion.transferOwnership(address(0x1));
    }

    function test_EncodeStreamId() public {
        address userEncoded = address(0x1);
        uint64 startTimeEncoded = 1669852800;

        uint256 streamId = conversion.encodeStreamId(
            userEncoded,
            startTimeEncoded
        );
        (address userDecoded, uint64 startTimeDecoded) = conversion
            .decodeStreamId(streamId);

        assertEq(userDecoded, userEncoded);
        assertEq(startTimeDecoded, startTimeEncoded);
    }

    function test_Convert() public {
        // 750 FDT is converted to 1 BOND
        uint256 streamId = conversion.convert(750 ether, address(this));
        (uint128 total, uint128 claimed) = conversion.streams(streamId);

        assertEq(total, 1 ether);
        assertEq(claimed, 0);
    }

    function test_CannotConvertToZeroAddress() public {
        // fails to convert to zero address
        vm.expectRevert(Invalid_Stream_Owner.selector);
        conversion.convert(75000 ether, address(0));
    }

    function test_CannotConvertIfInsufficientReserves() public {
        // fails to convert an amount larger than available reserves (1000 BOND)
        vm.expectRevert(Insufficient_Reserves.selector);
        conversion.convert(750001 ether, address(this));

        // can convert up to available reserves (1000 BOND)
        uint256 streamId = conversion.convert(750000 ether, address(this));
        (uint128 total, uint128 claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 1000 ether);

        // cannot convert if no reserves left
        vm.expectRevert(Insufficient_Reserves.selector);
        conversion.convert(750 ether, address(this));

        // can claim from stream
        // move block.timestamp by 73 days (1/5-th of vesting duration)
        skip(100 days);
        conversion.claim(streamId);
        (total, claimed) = conversion.streams(streamId);
        assertLt(total - claimed, 1000 ether);

        // can still not convert
        vm.expectRevert(Insufficient_Reserves.selector);
        conversion.convert(750 ether, address(this));

        // fill up reserves of conversion contract
        deal(
            address(bond),
            address(conversion),
            bond.balanceOf(address(conversion)) + 1000 ether
        );

        // can convert again
        console.log("%s", bond.balanceOf(address(conversion)));
        console.log("%s", conversion.totalUnclaimed());
        uint256 streamId2 = conversion.convert(750000 ether, address(this));
        assertGt(streamId2, streamId); // assert new streamId
        (uint128 total2, uint128 claimed2) = conversion.streams(streamId2);
        assertEq(total2 - claimed2, 1000 ether);
    }

    function test_Claim() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // initial balance
        (uint128 total, uint128 claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 100 ether);

        // move block.timestamp by 73 days (1/5-th of vesting duration)
        skip(73 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 20 ether);
        conversion.claim(streamId);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 20 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 80 ether);

        // move block.timestamp by another 73 days
        skip(73 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 20 ether);
        conversion.claim(streamId);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 40 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 60 ether);

        // move block.timestamp by another 73 days
        skip(73 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 20 ether);
        conversion.claim(streamId);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 60 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 40 ether);

        // move block.timestamp by another 73 days
        skip(73 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 20 ether);
        conversion.claim(streamId);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 80 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 20 ether);

        // move block.timestamp by another 73 days
        skip(73 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 20 ether);
        conversion.claim(streamId);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 100 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 0 ether);
    }

    function test_ClaimToDesignatedRecipient() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));
        address recipient = address(0x1);

        // initial balance
        (uint128 total, uint128 claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 100 ether);

        // move block.timestamp by 219 days (3/5-th of vesting duration)
        skip(219 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 60 ether);
        conversion.claim(streamId, recipient);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 0 ether);
        assertEq(bond.balanceOf(recipient), 60 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 40 ether);

        // move block.timestamp by another 146 days (2/5-th of vesting duration)
        skip(146 days);

        // balances pre/post claim
        assertEq(conversion.claimableBalance(streamId), 40 ether);
        conversion.claim(streamId, recipient);
        assertEq(conversion.claimableBalance(streamId), 0);
        assertEq(bond.balanceOf(address(this)), 0 ether);
        assertEq(bond.balanceOf(recipient), 100 ether);
        (total, claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 0 ether);
    }

    function test_OtherUsersCannotClaim() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // stream exists with correct balance
        (uint128 total, uint128 claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 100 ether);

        // claiming from non-stream owner fails
        vm.prank(address(0x1));
        vm.expectRevert(Only_Stream_Owner.selector);
        conversion.claim(streamId);
    }

    function test_CannotClaimToZeroAddress() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // stream exists with correct balance
        (uint128 total, uint128 claimed) = conversion.streams(streamId);
        assertEq(total - claimed, 100 ether);

        // move block.timestamp by 219 days (3/5-th of vesting duration)
        skip(219 days);

        // claiming to zero address fails
        vm.expectRevert(Invalid_Recipient.selector);
        conversion.claim(streamId, address(0));
    }

    function test_TransferStreamOwnership() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // test contract is the initial stream owner
        (address streamOwner, ) = conversion.decodeStreamId(streamId);
        assertEq(streamOwner, address(this));

        // transfer stream to new owner
        address newOwner = address(0x1);
        uint256 newStreamId = conversion.transferStreamOwnership(
            streamId,
            newOwner
        );
        (address newStreamOwner, ) = conversion.decodeStreamId(newStreamId);
        assertEq(newStreamOwner, newOwner);
    }

    function test_CannotTransferStreamOwnershipToZeroAddress() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // test contract is the initial stream owner
        (address streamOwner, ) = conversion.decodeStreamId(streamId);
        assertEq(streamOwner, address(this));

        // transfer stream to zero address fails
        vm.expectRevert(Invalid_Stream_Owner.selector);
        address newOwner = address(0);
        conversion.transferStreamOwnership(streamId, newOwner);
    }

    function test_CannotTransferStreamOwnershipToCurrentOwner() public {
        // 75000 FDT is converted to 100 BOND claimable over 1 year
        uint256 streamId = conversion.convert(75000 ether, address(this));

        // test contract is the initial stream owner
        (address streamOwner, ) = conversion.decodeStreamId(streamId);
        assertEq(streamOwner, address(this));

        // transfer stream to zero address fails
        vm.expectRevert(Invalid_Stream_Owner.selector);
        address newOwner = address(this);
        conversion.transferStreamOwnership(streamId, newOwner);
    }
}
