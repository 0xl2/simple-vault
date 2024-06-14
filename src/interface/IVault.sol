// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    enum ConfigType {
        DEPOSIT_MINIMUM,
        DEPOSIT_MAXIMUM,
        DEPOSIT_FEE
    }

    event SetConfig(ConfigType config, uint256 value);
    event SetTreasury(address treasuryAddress);
    event SetWhitelist(address account, bool flag);
    event GetAsset(address indexed strategy, uint256 amount, uint256 timestamp);
    event PutAsset(address indexed strategy, uint256 amount, uint256 timestamp);

    function putAsset(uint256 amount) external;

    function getAsset(uint256 amount) external;

    function setTreasury(address) external;

    function setConfig(ConfigType, uint256) external;
}
