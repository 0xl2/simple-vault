// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    error ZERO_AMOUNT();

    error ZERO_ADDRESS();

    error UnderMinDeposit(address receiver, uint256 assets, uint256 min);

    error ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    error NOT_WHITELISTED(address);
}
