"use client";

import React, { createContext, useContext, useState, useEffect, useCallback, useMemo } from "react";
import { ethers } from "ethers";
import { NETWORKS, CONTRACTS } from "@/lib/web3/config";
import { useToast } from "@/hooks/use-toast";

interface WalletState {
  address: string | null;
  chainId: number | null;
  isConnected: boolean;
  balance: string;
}

interface Web3ContextType {
  wallet: WalletState;
  connectWallet: () => Promise<void>;
  disconnectWallet: () => void;
  getContract: (address: string, abi: any) => ethers.Contract | null;
  provider: ethers.BrowserProvider | null;
  signer: ethers.Signer | null;
  refreshBalance: () => Promise<void>;
}

export const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export function useWeb3() {
  const context = useContext(Web3Context);
  if (context === undefined) {
    throw new Error("useWeb3 must be used within a Web3Provider");
  }
  return context;
}

export function Web3Provider({ children }: { children: React.ReactNode }) {
  const [wallet, setWallet] = useState<WalletState>({
    address: null,
    chainId: null,
    isConnected: false,
    balance: "0",
  });
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const { toast } = useToast();

  const refreshBalance = useCallback(async () => {
    if (wallet.address && provider) {
      try {
        const balance = await provider.getBalance(wallet.address);
        setWallet((prev) => ({
          ...prev,
          balance: ethers.formatEther(balance),
        }));
      } catch (error) {
        console.error("Error refreshing balance:", error);
      }
    }
  }, [wallet.address, provider]);

  const init = useCallback(async () => {
    if (typeof window !== "undefined" && window.ethereum) {
      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      setProvider(browserProvider);

      try {
        const accounts = await browserProvider.listAccounts();
        if (accounts.length > 0) {
          const signer = await browserProvider.getSigner();
          const address = await signer.getAddress();
          const network = await browserProvider.getNetwork();
          const balance = await browserProvider.getBalance(address);

          setSigner(signer);
          setWallet({
            address,
            chainId: Number(network.chainId),
            isConnected: true,
            balance: ethers.formatEther(balance),
          });
        }
      } catch (error) {
        console.error("Initialization error:", error);
      }

      window.ethereum.on("accountsChanged", (accounts: string[]) => {
        if (accounts.length === 0) {
          setWallet({
            address: null,
            chainId: null,
            isConnected: false,
            balance: "0",
          });
          setSigner(null);
        } else {
          init();
        }
      });

      window.ethereum.on("chainChanged", () => {
        window.location.reload();
      });
    }
  }, []);

  useEffect(() => {
    init();
  }, [init]);

  const connectWallet = async () => {
    if (typeof window !== "undefined" && window.ethereum) {
      try {
        const browserProvider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        if (accounts.length > 0) {
          await init();
          toast({
            title: "Wallet Connected",
            description: "Successfully connected to your wallet.",
          });
        }
      } catch (error: any) {
        toast({
          title: "Connection Failed",
          description: error.message || "Failed to connect wallet.",
          variant: "destructive",
        });
      }
    } else {
      toast({
        title: "Provider Not Found",
        description: "Please install MetaMask or another Web3 wallet.",
        variant: "destructive",
      });
    }
  };

  const disconnectWallet = () => {
    setWallet({
      address: null,
      chainId: null,
      isConnected: false,
      balance: "0",
    });
    setSigner(null);
    toast({
      title: "Wallet Disconnected",
      description: "You have disconnected your wallet.",
    });
  };

  const getContract = useCallback(
    (address: string, abi: any) => {
      if (!address || !abi || !provider) return null;
      return new ethers.Contract(address, abi, signer || provider);
    },
    [provider, signer]
  );

  const contextValue = useMemo(
    () => ({
      wallet,
      connectWallet,
      disconnectWallet,
      getContract,
      provider,
      signer,
      refreshBalance,
    }),
    [wallet, provider, signer, refreshBalance]
  );

  return <Web3Context.Provider value={contextValue}>{children}</Web3Context.Provider>;
}
