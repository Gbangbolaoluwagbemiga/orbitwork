"use client";

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingUp, ShieldCheck, Zap, Bot, Activity } from "lucide-react";
import { useWeb3 } from "@/contexts/web3-context";
import { ORBIT_WORK_ABI } from "@/lib/web3/abis";
import { CONTRACTS } from "@/lib/web3/config";
import { Badge } from "@/components/ui/badge";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { motion } from "framer-motion";

export function YieldStatus() {
  const { wallet, getContract } = useWeb3();
  const [isVerified, setIsVerified] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function checkVerification() {
      if (wallet.isConnected && wallet.address) {
        try {
          const contract = getContract(CONTRACTS.ORBIT_WORK_ESCROW, ORBIT_WORK_ABI);
          const verified = await contract.call("selfVerifiedUsers", wallet.address);
          setIsVerified(verified);
        } catch (error) {
          console.error("Failed to check verification:", error);
        } finally {
          setLoading(false);
        }
      }
    }
    checkVerification();
  }, [wallet.isConnected, wallet.address, getContract]);

  if (!wallet.isConnected) return null;

  const container = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const item = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0 }
  };

  return (
    <motion.div 
      variants={container}
      initial="hidden"
      animate="show"
      className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8"
    >
      <motion.div variants={item}>
        <Card className="glass border-primary/20 overflow-hidden relative group h-full">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <Zap className="w-12 h-12 text-primary" />
          </div>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <TrendingUp className="w-4 h-4 mr-2 text-primary" />
              Liquid Escrow Yield
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline space-x-2">
              <span className="text-2xl font-bold text-primary">Yield Bearing</span>
              <Badge variant="secondary" className="bg-primary/10 text-primary border-primary/20">
                Uniswap v4
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Funds are earning LP fees in v4 pools during escrow.
            </p>
          </CardContent>
        </Card>
      </motion.div>

      <motion.div variants={item}>
        <Card className="glass border-purple-500/20 overflow-hidden relative group h-full">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <Bot className="w-12 h-12 text-purple-500" />
          </div>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <Activity className="w-4 h-4 mr-2 text-purple-500" />
              Reactive Automation
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline space-x-2">
              <span className="text-2xl font-bold text-purple-500">Autonomous</span>
              <Badge variant="secondary" className="bg-purple-500/10 text-purple-500 border-purple-500/20">
                Kopli/Lasna
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Reactive Network monitors and auto-approves milestones.
            </p>
          </CardContent>
        </Card>
      </motion.div>

      <motion.div variants={item}>
        <Card className="glass border-accent/20 overflow-hidden relative group h-full">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <ShieldCheck className="w-12 h-12 text-accent" />
          </div>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center">
              <ShieldCheck className="w-4 h-4 mr-2 text-accent" />
              Dynamic Fee Discount
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="h-8 w-24 bg-muted animate-pulse rounded" />
            ) : (
              <>
                <div className="flex items-center space-x-2">
                  <span className={`text-2xl font-bold ${isVerified ? "text-accent" : "text-muted-foreground"}`}>
                    {isVerified ? "-50%" : "Full Fee"}
                  </span>
                  {isVerified ? (
                    <Badge className="bg-accent/10 text-accent border-accent/20">
                      Verified
                    </Badge>
                  ) : (
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger>
                          <Badge variant="outline" className="cursor-help">
                            0.30%
                          </Badge>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Complete Self Protocol verification for discounts.</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  )}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {isVerified
                    ? "Enjoy reduced protocol fees via Self Protocol."
                    : "Verify ID to unlock 50% platform fee discount."}
                </p>
              </>
            )}
          </CardContent>
        </Card>
      </motion.div>
    </motion.div>
  );
}
