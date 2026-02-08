"use client";

import { useState, useEffect } from "react";
import { Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { useWeb3 } from "@/contexts/web3-context";
import { useToast } from "@/hooks/use-toast";
import { CONTRACTS } from "@/lib/web3/config";
import { ORBITWORK_RATINGS_ABI } from "@/lib/web3/ratings-abi";

interface RateFreelancerProps {
  escrowId: string;
  freelancerAddress: string;
  onRated?: () => void;
  existingRating?: { rating: number; exists: boolean };
}

export function RateFreelancer({
  escrowId,
  freelancerAddress,
  onRated,
  existingRating,
}: RateFreelancerProps) {
  const { getContract, wallet } = useWeb3();
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(false);
  const [rating, setRating] = useState(0);
  const [hoveredRating, setHoveredRating] = useState(0);
  const [comment, setComment] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [hasRated, setHasRated] = useState(existingRating?.exists || false);
  const [currentRating, setCurrentRating] = useState(
    existingRating?.rating || 0
  );

  // Update state when existingRating changes
  useEffect(() => {
    if (existingRating) {
      setHasRated(existingRating.exists);
      setCurrentRating(existingRating.rating);
    }
  }, [existingRating]);

  // Check if already rated when dialog opens
  useEffect(() => {
    if (isOpen && wallet.address && !hasRated) {
      checkIfRated();
    }
  }, [isOpen, wallet.address]);

  const checkIfRated = async () => {
    try {
      const contract = getContract(CONTRACTS.ORBITWORK_RATINGS, ORBITWORK_RATINGS_ABI);
      if (!contract) return;

      const rated = await contract.call("hasRated", escrowId, wallet.address);
      if (rated) {
        setHasRated(true);
        // We can't easily get the score without fetching all ratings, simplified for now
        // But we can inform the user
      }
    } catch (e) {
      console.log("Error checking rating status:", e);
    }
  }

  const handleSubmitRating = async () => {
    if (hasRated) {
      toast({
        title: "Already Rated",
        description: "You have already rated this transaction",
        variant: "destructive",
      });
      return;
    }

    if (rating === 0) {
      toast({
        title: "Please select a rating",
        description: "You must select a rating from 1-5 stars",
        variant: "destructive",
      });
      return;
    }

    setIsSubmitting(true);
    try {
      const contract = getContract(CONTRACTS.ORBITWORK_RATINGS, ORBITWORK_RATINGS_ABI);
      if (!contract) {
        throw new Error("Contract not available");
      }

      console.log("Submitting rating:", escrowId, rating, comment);
      await contract.send("rateTransaction", "no-value", escrowId, rating, comment);

      toast({
        title: "Rating submitted",
        description: `You rated this interaction ${rating} out of 5 stars`,
      });

      setHasRated(true);
      setCurrentRating(rating);
      setIsOpen(false);
      setRating(0);
      setComment("");
      if (onRated) onRated();
    } catch (error: any) {
      console.error("Error submitting rating:", error);
      toast({
        title: "Rating failed",
        description: error.message || "Failed to submit rating",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  // If already rated, show the rating (if known) or just "Rated"
  if (hasRated) {
    return (
      <div className="flex items-center gap-2">
        <div className="flex items-center gap-1">
          {[1, 2, 3, 4, 5].map((star) => (
            <Star
              key={star}
              className={`h-4 w-4 ${star <= currentRating
                  ? "fill-yellow-400 text-yellow-400"
                  : "text-gray-300"
                }`}
            />
          ))}
        </div>
        <span className="text-sm font-medium">Rated {currentRating > 0 ? `${currentRating}/5` : ""}</span>
      </div>
    );
  }

  return (
    <>
      <Button
        onClick={() => setIsOpen(true)}
        variant="outline"
        size="sm"
        className="gap-2"
        disabled={hasRated}
      >
        <Star className="h-4 w-4" />
        Rate Experience
      </Button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Rate Experience</DialogTitle>
            <DialogDescription>
              How would you rate your experience with this transaction?
            </DialogDescription>
            <div className="mt-2 text-sm text-muted-foreground">
              Escrow ID: {escrowId}
            </div>
          </DialogHeader>

          <div className="space-y-4">
            <div className="flex justify-center gap-2 py-4">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  type="button"
                  onClick={() => setRating(star)}
                  onMouseEnter={() => setHoveredRating(star)}
                  onMouseLeave={() => setHoveredRating(0)}
                  className="transition-transform hover:scale-110"
                >
                  <Star
                    className={`h-10 w-10 ${star <= (hoveredRating || rating)
                        ? "fill-yellow-400 text-yellow-400"
                        : "text-gray-300"
                      }`}
                  />
                </button>
              ))}
            </div>

            {rating > 0 && (
              <div className="text-center text-sm text-muted-foreground">
                You selected {rating} out of 5 stars
              </div>
            )}

            <div className="space-y-2">
              <label className="text-sm font-medium">Comment (Optional)</label>
              <Textarea
                placeholder="Share your experience..."
                value={comment}
                onChange={(e) => setComment(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setIsOpen(false);
                setRating(0);
                setComment("");
              }}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button
              onClick={handleSubmitRating}
              disabled={rating === 0 || isSubmitting}
            >
              {isSubmitting ? "Submitting..." : "Submit Rating"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
