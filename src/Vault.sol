// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Errors} from "src/utils/Errors.sol";
import {IVault} from "src/interface/IVault.sol";

contract Vault is IVault, ERC4626, Ownable {
    using SafeERC20 for IERC20;

    uint256 private minDepositAmount;

    uint256 private maxDepositAmount;

    uint256 private depositFee;

    address public treasury;

    mapping(address => bool) internal whitelisted;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 asset,
        address ownerAddress
    ) ERC4626(asset) ERC20(name, symbol) Ownable(ownerAddress) {}

    modifier onlyWhitelisted() {
        if (!whitelisted[_msgSender()])
            revert Errors.NOT_WHITELISTED(_msgSender());
        _;
    }

    function setConfig(ConfigType config, uint256 value) external onlyOwner {
        if (config == ConfigType.DEPOSIT_MINIMUM) minDepositAmount = value;
        else if (config == ConfigType.DEPOSIT_MAXIMUM) maxDepositAmount = value;
        else if (config == ConfigType.DEPOSIT_FEE) depositFee = value;

        emit SetConfig(config, value);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert Errors.ZERO_ADDRESS();

        treasury = _treasury;
        emit SetTreasury(treasury);
    }

    function setWhitelist(address account, bool flag) external onlyOwner {
        whitelisted[account] = flag;
        emit SetWhitelist(account, flag);
    }

    function maxDeposit(address) public view override returns (uint256) {
        return maxDepositAmount;
    }

    function minDeposit(address) external view returns (uint256) {
        return minDepositAmount;
    }

    function getDepositFee() external view returns (uint256) {
        return depositFee;
    }

    function checkWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        if (assets == 0) return 0;

        // check min deposit amount
        if (assets < minDepositAmount) {
            revert Errors.UnderMinDeposit(receiver, assets, minDepositAmount);
        }

        // check max deposit amount
        if (assets > maxDepositAmount) {
            revert Errors.ExceededMaxDeposit(
                receiver,
                assets,
                maxDepositAmount
            );
        }

        // take deposit fee
        unchecked {
            if (depositFee != 0) {
                uint256 fee = (assets * depositFee) / 1e4;

                // transfer fee to treasury
                IERC20(asset()).safeTransferFrom(_msgSender(), treasury, fee);

                // then update assets amount
                assets -= fee;
            }
        }

        // then do usual deposit
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function getAsset(uint256 amount) external onlyWhitelisted {
        if (amount == 0) revert Errors.ZERO_AMOUNT();

        // transfer token
        IERC20(asset()).safeTransfer(_msgSender(), amount);

        emit GetAsset(_msgSender(), amount, block.timestamp);
    }

    function putAsset(uint256 amount) external {
        if (amount == 0) revert Errors.ZERO_AMOUNT();

        // transfer token
        IERC20(asset()).safeTransferFrom(_msgSender(), address(this), amount);

        emit PutAsset(_msgSender(), amount, block.timestamp);
    }
}
