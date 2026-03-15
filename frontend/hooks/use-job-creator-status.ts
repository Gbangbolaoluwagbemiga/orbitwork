import { useState, useEffect, useCallback } from "react";
import { useWeb3 } from "@/contexts/web3-context";

export function useJobCreatorStatus() {
  const { wallet } = useWeb3();
  const { isConnected, address } = wallet;
  const [isJobCreator, setIsJobCreator] = useState(false);
  const [loading, setLoading] = useState(true);

  const checkJobCreatorStatus = useCallback(async () => {
    if (!isConnected || !address) {
      setIsJobCreator(false);
      setLoading(false);
      return;
    }

    setLoading(true);
    try {
      setIsJobCreator(false);
    } catch (error) {
      setIsJobCreator(false);
    } finally {
      setLoading(false);
    }
  }, [isConnected, address]);

  useEffect(() => {
    checkJobCreatorStatus();
  }, [checkJobCreatorStatus]);

  return { isJobCreator, loading };
}
