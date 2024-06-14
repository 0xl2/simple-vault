// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MintableToken} from "src/mock/MintableToken.sol";
import {Vault} from "src/Vault.sol";
import {Errors} from "src/utils/Errors.sol";
import {IVault} from "src/interface/IVault.sol";

contract VaultTest is Test {
    // generate users
    address public owner = makeAddr("owner");
    address public whitelisted = makeAddr("whitelisted");
    address public treasury = makeAddr("treasury");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    MintableToken public underlying;
    Vault public vault;

    uint256 minDeposit = 100 * 1e18;
    uint256 maxDeposit = 1_000_000 * 1e18;
    uint256 mintAmount = 10_000_000 * 1e18;
    uint256 depositFee = 1e2;

    function setUp() public {
        underlying = new MintableToken("Underlying token", "UT");
        vault = new Vault(
            "UT Vault",
            "UTV",
            IERC20(address(underlying)),
            owner
        );

        vm.startPrank(owner);

        // set treasury
        vault.setTreasury(treasury);

        // set whitelist
        vault.setWhitelist(whitelisted, true);

        // set min, max deposit amount and depositFee
        vault.setConfig(IVault.ConfigType.DEPOSIT_MINIMUM, minDeposit); // 100 UT

        vault.setConfig(IVault.ConfigType.DEPOSIT_MAXIMUM, maxDeposit); // 1M UT

        vault.setConfig(IVault.ConfigType.DEPOSIT_FEE, depositFee); // 1%

        // mint token and approve
        _mintAndApprove(alice, mintAmount);
        _mintAndApprove(bob, mintAmount);
    }

    function _mintAndApprove(address account, uint256 amount) internal {
        vm.startPrank(account);

        underlying.mint(account, amount);
        underlying.approve(address(vault), type(uint256).max);
    }

    function test_CheckCofig() public view {
        // check treasury
        assertEq(vault.treasury(), treasury);

        assertEq(vault.maxDeposit(alice), maxDeposit);
        assertEq(vault.maxDeposit(bob), maxDeposit);

        assertEq(vault.minDeposit(alice), minDeposit);
        assertEq(vault.minDeposit(bob), minDeposit);

        assertEq(vault.getDepositFee(), depositFee);
    }

    function test_VaultFunc() public {
        // check minimum depoist amount
        {
            uint256 depositAmount = 99.9 * 1e18;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.UnderMinDeposit.selector,
                    alice,
                    depositAmount,
                    minDeposit
                )
            );
            vault.deposit(depositAmount, alice);

            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.UnderMinDeposit.selector,
                    bob,
                    depositAmount,
                    minDeposit
                )
            );
            vault.deposit(depositAmount, bob);
        }

        // check max deposit amount
        {
            uint256 depositAmount = maxDeposit + 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.ExceededMaxDeposit.selector,
                    alice,
                    depositAmount,
                    maxDeposit
                )
            );
            vault.deposit(depositAmount, alice);

            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.ExceededMaxDeposit.selector,
                    bob,
                    depositAmount,
                    maxDeposit
                )
            );
            vault.deposit(depositAmount, bob);
        }

        // deposit success for Alice
        uint256 aliceDeposit = 1000 * 1e18;
        {
            vm.startPrank(alice);
            vault.deposit(aliceDeposit, alice);

            // check treasury balance
            assertEq(
                underlying.balanceOf(treasury),
                (aliceDeposit * depositFee) / 1e4
            );
            assertGt(vault.balanceOf(alice), 0);
        }

        // deposit success for Bob
        uint256 bobDeposit = 10000 * 1e18;
        {
            vm.startPrank(bob);
            uint256 beforeTreasury = underlying.balanceOf(treasury);
            vault.deposit(bobDeposit, bob);

            // check treasury balance
            assertEq(
                underlying.balanceOf(treasury),
                beforeTreasury + (bobDeposit * depositFee) / 1e4
            );
            assertGt(vault.balanceOf(bob), 0);
        }

        // only whitelist can transfer tokens from vault
        {
            uint256 getAmount = 10000 * 1e18;
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.NOT_WHITELISTED.selector, alice)
            );
            vault.getAsset(getAmount);

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.NOT_WHITELISTED.selector, bob)
            );
            vault.getAsset(getAmount);

            // even owner can not get asset
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.NOT_WHITELISTED.selector, owner)
            );
            vault.getAsset(getAmount);

            // only get non-zero amount
            vm.startPrank(whitelisted);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
            );
            vault.getAsset(0);

            // getAsset success
            assertEq(underlying.balanceOf(whitelisted), 0);
            vault.getAsset(getAmount);
            assertEq(underlying.balanceOf(whitelisted), getAmount);
        }

        // anyone can put tokens in contract
        uint256 putAmount = 100 * 1e18;
        {
            uint256 beforeAmount = underlying.balanceOf(address(vault));
            vm.startPrank(alice);
            vault.putAsset(putAmount);
            assertEq(
                beforeAmount + putAmount,
                underlying.balanceOf(address(vault))
            );

            vm.startPrank(bob);
            beforeAmount = underlying.balanceOf(address(vault));
            vault.putAsset(putAmount);
            assertEq(
                beforeAmount + putAmount,
                underlying.balanceOf(address(vault))
            );

            _mintAndApprove(whitelisted, putAmount);

            vm.startPrank(whitelisted);
            vault.putAsset(10000 * 1e18);
            vault.putAsset(putAmount);
        }

        // check withdraw
        {
            aliceDeposit -= (aliceDeposit * depositFee) / 1e4;
            bobDeposit -= (bobDeposit * depositFee) / 1e4;
            putAmount *= 3;

            assertGt(
                vault.convertToAssets(vault.balanceOf(alice)),
                aliceDeposit
            );
            assertGt(vault.convertToAssets(vault.balanceOf(bob)), bobDeposit);

            assertEq(vault.balanceOf(alice), aliceDeposit);

            // alice withdraw
            vm.startPrank(alice);
            uint256 aliceBalance = underlying.balanceOf(alice);
            aliceDeposit = vault.convertToAssets(vault.balanceOf(alice));

            vault.redeem(vault.balanceOf(alice), alice, alice);

            assertEq(underlying.balanceOf(alice), aliceDeposit + aliceBalance);

            vm.startPrank(bob);
            uint256 bobBalance = underlying.balanceOf(bob);
            bobDeposit = vault.convertToAssets(vault.balanceOf(bob));

            vault.redeem(vault.balanceOf(bob), bob, bob);

            assertEq(underlying.balanceOf(bob), bobDeposit + bobBalance);
            assertApproxEqAbs(underlying.balanceOf(address(vault)), 0, 1);
        }
    }
}
