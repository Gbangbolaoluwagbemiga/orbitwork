import { useState, useEffect, useCallback } from "react";
import { useWeb3 } from "@/contexts/web3-context";

export function useFreelancerStatus() {
  const { wallet } = useWeb3();
  const { isConnected, address } = wallet;
  const [isFreelancer, setIsFreelancer] = useState(false);
  const [loading, setLoading] = useState(false);

  const checkFreelancerStatus = useCallback(async () => {
    if (!isConnected || !address) {
      setIsFreelancer(false);
      setLoading(false);
      return;
    }

    setLoading(true);
    try {
      setIsFreelancer(false);
    } catch (error) {
      setIsFreelancer(false);
    } finally {
      setLoading(false);
    }
  }, [isConnected, address]);

  useEffect(() => {
    checkFreelancerStatus();
  }, [checkFreelancerStatus]);

  return { isFreelancer, loading };
}
