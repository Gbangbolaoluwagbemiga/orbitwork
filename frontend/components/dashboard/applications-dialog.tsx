"use client";

import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ApplicationCard } from "@/components/approvals/application-card";
import { useWeb3 } from "@/contexts/web3-context";
import { useToast } from "@/hooks/use-toast";
import { contractService } from "@/lib/web3/contract-service";
import type { Application } from "@/lib/web3/types";
import { Loader2 } from "lucide-react";

interface ApplicationsDialogProps {
  escrowId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onHire: (freelancer: string) => void;
}

export function ApplicationsDialog({
  escrowId,
  open,
  onOpenChange,
  onHire,
}: ApplicationsDialogProps) {
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [hiring, setHiring] = useState<string | null>(null);
  const { wallet } = useWeb3();
  const { toast } = useToast();

  useEffect(() => {
    if (open && escrowId) {
      fetchApplications();
    }
  }, [open, escrowId]);

  const fetchApplications = async () => {
    setLoading(true);
    try {
      // In a real app, this would fetch from a backend or events
      // For now, we'll try to get existing applications if any
      const apps = await contractService.getApplications(Number(escrowId));
      setApplications(apps || []);
    } catch (error) {
      console.error("Error fetching applications:", error);
      // setApplications([]);
    } finally {
      setLoading(false);
    }
  };

  const handleHire = async (freelancer: string) => {
    if (!wallet.address) return;
    setHiring(freelancer);
    try {
      await contractService.selectFreelancer(Number(escrowId), freelancer, wallet.address);
      toast({
        title: "Freelancer Hired",
        description: "The freelancer has been successfully assigned to the project.",
      });
      onHire(freelancer);
      onOpenChange(false);
    } catch (error: any) {
      toast({
        title: "Hiring Failed",
        description: error.message || "Could not hire freelancer",
        variant: "destructive",
      });
    } finally {
      setHiring(null);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="glass max-w-3xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Project Applications</DialogTitle>
          <DialogDescription>
            Review and hire freelancers for project #{escrowId}
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-primary truncate mb-2" />
              <p className="text-sm text-muted-foreground">Loading applications...</p>
            </div>
          ) : applications.length === 0 ? (
            <div className="text-center py-12 border-2 border-dashed border-muted rounded-xl">
              <p className="text-muted-foreground">No applications found for this project yet.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {applications.map((app, index) => (
                <ApplicationCard
                  key={index}
                  application={app}
                  index={index}
                  onApprove={() => handleHire(app.freelancerAddress)}
                  approving={hiring === app.freelancerAddress}
                />
              ))}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
