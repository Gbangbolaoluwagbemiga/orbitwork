/**
 * Admin hooks for contract administration
 */

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "@/hooks/use-toast";
import { useWeb3 } from "@/contexts/web3-context";
import { CONTRACTS } from "@/lib/web3/config";
import { ORBIT_WORK_ABI } from "@/lib/web3/abis";

/**
 * Hook to initialize the contract
 */
export function useInitContract() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async () => {
      if (!wallet.isConnected) throw new Error("Wallet not connected");
      
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("initialize", []); 
      return tx.hash;
    },
    onSuccess: (txHash) => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "✅ Contract initialized successfully!",
        description: `Transaction hash: ${txHash?.slice(0, 16)}...${txHash?.slice(-8)}`,
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Initialization Failed",
        description: error.message || "Failed to initialize contract.",
        variant: "destructive",
      });
    },
  });
}

/**
 * Hook to pause job creation
 */
export function usePauseJobCreation() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async () => {
      if (!wallet.isConnected) throw new Error("Wallet not connected");
      
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("pause", []);
      localStorage.setItem('contractPaused', 'true');
      return tx.hash;
    },
    onSuccess: (txHash) => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "✅ Contract paused successfully!",
        description: `Transaction hash: ${txHash?.slice(0, 16)}...${txHash?.slice(-8)}`,
      });
    },
  });
}

/**
 * Hook to unpause job creation
 */
export function useUnpauseJobCreation() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async () => {
      if (!wallet.isConnected) throw new Error("Wallet not connected");
      
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("unpause", []);
      localStorage.setItem('contractPaused', 'false');
      return tx.hash;
    },
    onSuccess: (txHash) => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "✅ Contract unpaused successfully!",
        description: `Transaction hash: ${txHash?.slice(0, 16)}...${txHash?.slice(-8)}`,
      });
    },
  });
}

/**
 * Hook to set platform fee
 */
export function useSetPlatformFee() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async (feeBP: number) => {
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("setPlatformFee", [feeBP]);
      return tx.hash;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "Platform fee updated",
        description: "Platform fee has been updated successfully",
      });
    },
  });
}

/**
 * Hook to set fee collector
 */
export function useSetFeeCollector() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async (feeCollector: string) => {
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("setFeeCollector", [feeCollector]);
      return tx.hash;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "Fee collector updated",
        description: "Fee collector has been updated successfully",
      });
    },
  });
}

/**
 * Hook to whitelist token
 */
export function useWhitelistToken() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async (token: string) => {
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("whitelist_token", [token]);
      return tx.hash;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "Token whitelisted",
        description: "Token has been whitelisted successfully",
      });
    },
  });
}

/**
 * Hook to authorize arbiter
 */
export function useAuthorizeArbiter() {
  const queryClient = useQueryClient();
  const { wallet, getContract } = useWeb3();

  return useMutation({
    mutationFn: async (arbiter: string) => {
      const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
      const tx = await contract.call("authorize_arbiter", [arbiter]);
      return tx.hash;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin"] });
      toast({
        title: "Arbiter authorized",
        description: "Arbiter has been authorized successfully",
      });
    },
  });
}
