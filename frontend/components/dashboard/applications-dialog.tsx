import { useState } from "react";
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Loader2, User, Star, Briefcase, Calendar } from "lucide-react";
import { CONTRACTS } from "@/lib/web3/config";
import { ORBIT_WORK_ABI } from "@/lib/web3/abis";
import { ORBITWORK_RATINGS_ABI } from "@/lib/web3/ratings-abi";
import { useWeb3 } from "@/contexts/web3-context";
import { useToast } from "@/hooks/use-toast";
import { useSmartAccount } from "@/contexts/smart-account-context";
import { ethers } from "ethers";

interface Application {
    freelancer: string;
    coverLetter: string;
    proposedTimeline: number;
    appliedAt: number;
    exists: boolean;
    averageRating: number;
    totalRatings: number;
}

interface ApplicationsDialogProps {
    escrowId: string;
    open: boolean;
    onOpenChange: (open: boolean) => void;
    onHire: () => void;
}

export function ApplicationsDialog({
    escrowId,
    open,
    onOpenChange,
    onHire,
}: ApplicationsDialogProps) {
    const { getContract, wallet } = useWeb3();
    const { executeTransaction, isSmartAccountReady } = useSmartAccount();
    const { toast } = useToast();
    const [applications, setApplications] = useState<Application[]>([]);
    const [loading, setLoading] = useState(false);
    const [hiringFreelancer, setHiringFreelancer] = useState<string | null>(null);

    const fetchApplications = async () => {
        if (!open) return;
        setLoading(true);
        try {
            const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
            const ratingsContract = getContract(CONTRACTS.ORBITWORK_RATINGS, ORBITWORK_RATINGS_ABI);

            const apps = await contract.call(
                "getApplicationsPage",
                escrowId,
                0,
                50 // Max limit
            );

            // Parse applications
            const parsedApps = await Promise.all(
                apps.map(async (app: any) => {
                    const freelancer = app.freelancer || app[0];
                    const coverLetter = app.coverLetter || app[1];
                    const proposedTimeline = Number(app.proposedTimeline || app[2]);
                    const appliedAt = Number(app.appliedAt || app[3]);

                    // Fetch ratings
                    let averageRating = 0;
                    let totalRatings = 0;
                    try {
                        if (ratingsContract) {
                            averageRating = Number(await ratingsContract.call("getAverageRating", freelancer));
                            totalRatings = Number(await ratingsContract.call("getRatingCount", freelancer));
                        }
                    } catch (e) {
                        console.warn("Failed to fetch ratings", e);
                    }

                    return {
                        freelancer,
                        coverLetter,
                        proposedTimeline,
                        appliedAt,
                        exists: true,
                        averageRating,
                        totalRatings
                    };
                })
            );

            setApplications(parsedApps);
        } catch (error) {
            console.error("Failed to fetch applications:", error);
            toast({
                title: "Error",
                description: "Failed to load applications",
                variant: "destructive",
            });
        } finally {
            setLoading(false);
        }
    };

    const handleHire = async (freelancer: string) => {
        setHiringFreelancer(freelancer);
        try {
            if (isSmartAccountReady) {
                const { ethers } = await import("ethers");
                const iface = new ethers.Interface(ORBIT_WORK_ABI);
                const data = iface.encodeFunctionData("acceptFreelancer", [
                    escrowId,
                    freelancer,
                ]);

                await executeTransaction(CONTRACTS.ORBIT_WORK_ESCROW, data, "0");
            } else {
                const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
                const txHash = await contract.send(
                    "acceptFreelancer",
                    "no-value",
                    escrowId,
                    freelancer
                );

                // Wait for confirmation
                if (typeof window !== "undefined" && window.ethereum) {
                    const provider = new ethers.BrowserProvider(window.ethereum as any);
                    await provider.waitForTransaction(txHash);
                }
            }

            toast({
                title: "Freelancer Hired!",
                description: "The job has been assigned. You can now fund the escrow.",
            });
            onHire();
            onOpenChange(false);
        } catch (error: any) {
            console.error("Hiring failed:", error);
            toast({
                title: "Hiring Failed",
                description: error.message || "Could not hire freelancer",
                variant: "destructive",
            });
        } finally {
            setHiringFreelancer(null);
        }
    };

    // Fetch when opened
    if (open && applications.length === 0 && !loading) {
        // Use effect or just call it here? Better use effect.
    }

    // Use a timeout to avoid infinite loop in render if calling directly
    useState(() => {
        if (open) fetchApplications();
    });

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-3xl glass border-primary/20">
                <DialogHeader>
                    <DialogTitle>Job Applications</DialogTitle>
                    <DialogDescription>
                        Review applications and hire a freelancer for this job.
                    </DialogDescription>
                </DialogHeader>

                <ScrollArea className="max-h-[60vh] mt-4 pr-4">
                    {loading ? (
                        <div className="flex justify-center p-8">
                            <Loader2 className="h-8 w-8 animate-spin text-primary" />
                        </div>
                    ) : applications.length === 0 ? (
                        <div className="text-center py-12 text-muted-foreground">
                            <User className="h-12 w-12 mx-auto mb-4 opacity-50" />
                            <p>No applications yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {applications.map((app, index) => (
                                <div
                                    key={index}
                                    className="p-4 rounded-lg bg-white/5 border border-white/10 hover:border-primary/30 transition-colors"
                                >
                                    <div className="flex flex-col md:flex-row justify-between gap-4">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-3 mb-2">
                                                <Avatar className="h-8 w-8">
                                                    <AvatarFallback>{app.freelancer.slice(2, 4).toUpperCase()}</AvatarFallback>
                                                </Avatar>
                                                <span className="font-mono text-sm text-muted-foreground">
                                                    {app.freelancer.slice(0, 6)}...{app.freelancer.slice(-4)}
                                                </span>
                                                {app.averageRating > 0 && (
                                                    <Badge variant="outline" className="gap-1 bg-yellow-500/10 text-yellow-500 border-yellow-500/20">
                                                        <Star className="h-3 w-3 fill-current" />
                                                        {app.averageRating / 10} ({app.totalRatings})
                                                    </Badge>
                                                )}
                                            </div>

                                            <div className="mb-3">
                                                <h4 className="text-sm font-semibold mb-1">Cover Letter:</h4>
                                                <p className="text-sm text-foreground/90 whitespace-pre-wrap bg-black/20 p-3 rounded-md">
                                                    {app.coverLetter}
                                                </p>
                                            </div>

                                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                                                <span className="flex items-center gap-1">
                                                    <Briefcase className="h-3 w-3" />
                                                    Applied {new Date(app.appliedAt * 1000).toLocaleDateString()}
                                                </span>
                                                <span className="flex items-center gap-1">
                                                    <Calendar className="h-3 w-3" />
                                                    Proposed Timeline: {Math.ceil(app.proposedTimeline / (24 * 60 * 60))} days
                                                </span>
                                            </div>
                                        </div>

                                        <div className="flex items-start">
                                            <Button
                                                onClick={() => handleHire(app.freelancer)}
                                                disabled={!!hiringFreelancer}
                                                size="sm"
                                            >
                                                {hiringFreelancer === app.freelancer ? (
                                                    <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Hiring...</>
                                                ) : "Hire Freelancer"}
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </ScrollArea>
            </DialogContent>
        </Dialog>
    );
}
