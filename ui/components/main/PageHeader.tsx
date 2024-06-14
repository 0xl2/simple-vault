import { WalletConnect } from "../common/WalletConnect";
import { useAddress, useNetworkMismatch } from "@thirdweb-dev/react";

export const PageHeader = () => {
  const address = useAddress();
  const isMismatched = useNetworkMismatch();

  return (
    <header className="bg-white">
      <nav
        className="mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8"
        aria-label="Global"
      >
        <div className="flex flex-1">
          <a href="/" className="-m-1.5 p-1.5">
            <img className="h-8 w-auto" src="/logo.svg" alt="logo-svg" />
          </a>
        </div>
        {address && !isMismatched && (
          <span className="inline-flex rounded-md bg-purple-50 px-4 py-2 text-sm font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10 mr-5">
            {address.substring(0, 5)}
            ...
            {address.substring(address.length - 5)}
          </span>
        )}

        <WalletConnect />
      </nav>
    </header>
  );
};
