import { useState, useEffect } from "react";
import { useWeb3 } from "@/contexts/web3-context";
import { useDelegation } from "@/contexts/delegation-context";

export function useAdminStatus() {
  const { wallet } = useWeb3();
  const address = wallet.address;
  const isConnected = wallet.isConnected;
  const { delegations } = useDelegation();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isOwner, setIsOwner] = useState(false);
  const [isArbiter, setIsArbiter] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!isConnected || !address) {
      setIsAdmin(false);
      setIsOwner(false);
      setIsArbiter(false);
      return;
    }

    checkAdminStatus();
  }, [
    isConnected,
    address,
    delegations.length,
  ]);

  const checkAdminStatus = async () => {
    setLoading(true);
    try {
      // Determine active address
      const currentAddress = address;

      if (!currentAddress) {
        return;
      }

      // 1. Check against environment variable
      const envOwner = process.env.VITE_OWNER_ADDRESS || "";
      
      // Hackathon helper: If no VITE_OWNER_ADDRESS is set, treat the connected account as admin for demo
      if (!envOwner && isConnected && address) {
         console.log("No VITE_OWNER_ADDRESS set. Granting Admin access to connected wallet for demo.");
         setIsOwner(true);
         setIsAdmin(true);
         return;
      }

      if (
        envOwner &&
        currentAddress.toLowerCase().trim() === envOwner.toLowerCase().trim()
      ) {
        console.log("Admin access granted via VITE_OWNER_ADDRESS");
        setIsOwner(true);
        setIsAdmin(true);
        return;
      }

      // 2. TODO: Implement Contract owner check here
      
    } catch (error) {
      console.error("Error checking admin status:", error);
    } finally {
      setLoading(false);
    }
  };

  return { isAdmin, isOwner, isArbiter, loading };
}
