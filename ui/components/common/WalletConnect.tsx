import React, { useEffect } from "react";
import {
  useAddress,
  useDisconnect,
  useConnect,
  metamaskWallet,
  useNetworkMismatch,
  useSwitchChain,
  useChainId
} from "@thirdweb-dev/react";
import { Sepolia } from "@thirdweb-dev/chains";

import { showNotification, NotificationType } from "../../utils/notification";

export const WalletConnect = () => {
  const metamaskConfig = metamaskWallet();

  const address = useAddress();
  const chainId = useChainId();
  const disconnect = useDisconnect();
  const switchChain = useSwitchChain();
  const isMismatched = useNetworkMismatch();

  const connect = useConnect();

  useEffect(() => {
    switchNetwork();
  }, [address, chainId]);

  const switchNetwork = async (): Promise<void> => {
    if (isMismatched) {
      try {
        await switchChain(Sepolia.chainId);
      } catch (err) {
        showNotification("You are on wrong network", NotificationType.ERROR);
      }
    }
  };

  return (
    <button
      onClick={() =>
        address
          ? isMismatched
            ? switchNetwork()
            : disconnect()
          : connect(metamaskConfig)
      }
      className="rounded-full bg-rose-400 px-4 py-2 text-xs font-bold text-white lg:px-5 lg:py-3 lg:text-base"
    >
      {address
        ? isMismatched
          ? "Switch Network"
          : "Disconnect Wallet"
        : "Connect Wallet"}
    </button>
  );
};
