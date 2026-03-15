import { useState, useEffect } from "react";
import { useWeb3 } from "@/contexts/web3-context";

export function usePendingApprovals() {
  const { wallet } = useWeb3();
  const { isConnected, address } = wallet;
  const [hasPendingApprovals, setHasPendingApprovals] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!isConnected || !address) {
      setHasPendingApprovals(false);
      return;
    }

    checkPendingApprovals();
  }, [isConnected, address]);

  const checkPendingApprovals = async () => {
    setLoading(true);
    try {
      setHasPendingApprovals(false);
    } catch (error) {
      setHasPendingApprovals(false);
    } finally {
      setLoading(false);
    }
  };

  return {
    hasPendingApprovals,
    loading,
    refreshApprovals: checkPendingApprovals,
  };
}
