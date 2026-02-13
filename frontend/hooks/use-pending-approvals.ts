import { useState, useEffect } from "react";
import { useWeb3 } from "@/contexts/web3-context";
import { CONTRACTS } from "@/lib/web3/config";
import { SECUREFLOW_ABI } from "@/lib/web3/abis";

export function usePendingApprovals() {
  const { wallet, getContract } = useWeb3();
  const [hasPendingApprovals, setHasPendingApprovals] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!wallet.isConnected || !wallet.address) {
      setHasPendingApprovals(false);
      return;
    }

    checkPendingApprovals();
  }, [wallet.isConnected, wallet.address]);

  const checkPendingApprovals = async () => {
    setLoading(true);
    try {
      const contract = getContract(CONTRACTS.SECUREFLOW_ESCROW, SECUREFLOW_ABI);
      if (!contract) {
        setHasPendingApprovals(false);
        return;
      }

      // Get total number of escrows
      const totalEscrows = await contract.call("nextEscrowId");
      const escrowCount = Number(totalEscrows);

      // Check if current wallet has any jobs with applications
      if (escrowCount > 1) {
        // Fetch all escrow summaries in parallel to avoid N+1 problem
        const batchSize = 20; // Process in batches to avoid rate limiting
        let foundPending = false;

        for (let i = 1; i < escrowCount; i += batchSize) {
          if (foundPending) break;

          const end = Math.min(i + batchSize, escrowCount);
          const batchPromises = [];

          for (let j = i; j < end; j++) {
            batchPromises.push(
              contract.call("getEscrowSummary", j).then((summary: any) => ({
                id: j,
                summary
              })).catch(() => null)
            );
          }

          const results = await Promise.all(batchPromises);

          for (const res of results) {
            if (!res) continue;

            const { id, summary } = res;

            // Check if current user is the depositor (job creator)
            const isMyJob = summary[0].toLowerCase() === wallet.address?.toLowerCase();

            if (isMyJob) {
              // Check if this is an open job (no freelancer assigned yet)
              // isOpenJob is at index 12 based on other files, or check beneficiary address
              const beneficiary = summary[1];
              const isOpenJob = beneficiary === "0x0000000000000000000000000000000000000000";

              if (isOpenJob) {
                try {
                  // We still need to check application count
                  // This has to be done sequentially or in a sub-batch if we want to be super fast
                  // But typically user won't have THAT many open jobs
                  const applicationCount = await contract.call("getApplicationCount", id);
                  if (Number(applicationCount) > 0) {
                    setHasPendingApprovals(true);
                    setLoading(false);
                    return;
                  }
                } catch (e) {
                  continue;
                }
              }
            }
          }
        }
      }

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





