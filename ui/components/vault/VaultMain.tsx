import { utils } from "ethers";
import React, { useState } from "react";
import { useAddress, useContractWrite, useContract, useTokenBalance, useContractRead } from "@thirdweb-dev/react";
import { decodeError } from 'ethers-decode-error'

import { Spinner } from "../common/Spinner"
import { Contracts } from "../../utils/const";
import { showNotification, NotificationType } from "../../utils/notification";

export const VaultMain = () => {
  const [depositAmount, setDepositAmount] = useState<string>("");
  const [buttonLabel, setButtonLabel] = useState<string>("Deposit");
  const [loading, setLoading] = useState<boolean>(false);

  const address = useAddress();
  const { contract: tokenContract } = useContract(Contracts.underlyingToken, "token");
  const { contract: vaultContract } = useContract(Contracts.vault);

  const { mutateAsync: depositMutateAsync } = useContractWrite(
    vaultContract,
    "deposit"
  );

  const { mutateAsync: redeemMutateAsync } = useContractWrite(
    vaultContract,
    "redeem"
  );

  const { mutateAsync: approveMutateAsync } = useContractWrite(
    tokenContract,
    "approve"
  );

  const { data: balanceData, isLoading } = useTokenBalance(
    tokenContract,
    address,
  );
  const { data: vaultData, isLoading: vaultLoading } = useTokenBalance(
    vaultContract,
    address,
  );

  const { data: tokenAllowance } = useContractRead(tokenContract, "allowance", [address, Contracts.vault]);

  const { data: redeemAmount, isLoading: redeemLoading } = useContractRead(vaultContract, "convertToAssets", [vaultData?.value]);

  const userBalance = balanceData ? balanceData.value : utils.parseEther("0");

  const doDeposit = async () => {
    if (!address) {
      showNotification("Please connect wallet first", NotificationType.ERROR);
      return;
    }

    if (depositAmount.length == 0) {
      showNotification("Please insert deposit amount", NotificationType.ERROR);
      return;
    }

    const depositAmt = utils.parseEther(depositAmount);
    if (depositAmt.gt(userBalance)) {
      showNotification("Invalid deposit amount", NotificationType.ERROR);
    } else {
      try {
        setLoading(true);
        if (depositAmt.gt(tokenAllowance))
          await approveMutateAsync({ args: [Contracts.vault, depositAmt] })
        else
          await depositMutateAsync({ args: [depositAmt, address] });

        setLoading(false);
      } catch (err) {
        const { error } = decodeError(err)
        showNotification("Deposit failed with error: " + error, NotificationType.ERROR);

        setLoading(false);
      }
    }
  }

  const doRedeem = async () => {
    if (!address) {
      showNotification("Please connect wallet first", NotificationType.ERROR);
      return;
    }

    if (!vaultData) return;

    if (vaultData.value.eq(0)) {
      showNotification("No redeemable amount", NotificationType.ERROR);
    } else {
      try {
        setLoading(true);

        await redeemMutateAsync({ args: [vaultData.value, address, address] });

        setLoading(false);
      } catch (err) {
        const { error } = decodeError(err)
        showNotification("Redeem failed with error: " + error, NotificationType.ERROR);

        setLoading(false);
      }
    }
  }

  const checkAllowance = (val: string) => {
    setDepositAmount(val);
    if (tokenAllowance &&
      val.length > 0 &&
      utils.parseEther(val).gt(tokenAllowance)
    ) {
      setButtonLabel("Approve");
    } else {
      setButtonLabel("Deposit");
    }
  }

  return (
    <div className="mt-3">
      {loading && <Spinner />}
      <div className="font-bold text-xl mb-2">
        <p>Token Balance:{" "}
          {isLoading || !balanceData
            ? ""
            : balanceData.displayValue +
            " (" +
            balanceData.symbol +
            ")"}
        </p>
        <p>Your share:{" "}
          {vaultLoading || !vaultData
            ? ""
            : vaultData.displayValue +
            " (" +
            vaultData.symbol +
            ")"}
        </p>
        <p>Redeemable Amount:{" "}
          {redeemLoading || !redeemAmount || !balanceData
            ? ""
            : utils.formatEther(redeemAmount) +
            " (" +
            balanceData.symbol +
            ")"
          }
        </p>
      </div>
      <label>Deposit Amount</label>
      <div className="group flex max-h-[44px] flex-row items-center rounded-xl border border-gray/10 px-2 transition-all duration-300 ease-in-out max-w-[300px] bg-gray-300">
        <input
          type="number"
          maxLength={100}
          placeholder="Deposit"
          className="w-full border-0 placeholder:text-gray-500 focus:ring-0 bg-gray-300"
          value={depositAmount}
          disabled={loading}
          onChange={(e) => checkAllowance(e.target.value)}
        />
      </div>
      <button
        type="button"
        className="mr-2 mt-3 inline-flex w-full justify-center rounded-md px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:w-auto"
        onClick={() => doDeposit()}
        disabled={loading}
      >
        {buttonLabel}
      </button>
      <button
        type="button"
        className="mt-3 inline-flex w-full justify-center rounded-md px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:w-auto"
        onClick={() => doRedeem()}
        disabled={loading}
      >
        Redeem
      </button>
    </div>
  );
};
