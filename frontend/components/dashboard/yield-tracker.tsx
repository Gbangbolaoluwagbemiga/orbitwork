"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { TrendingUp, Droplet, Coins, Sparkles } from "lucide-react";

interface YieldTrackerProps {
    escrowId: string;
    totalAmount: number;
    tokenSymbol: string;
    daysActive: number;
}

export function YieldTracker({ escrowId, totalAmount, tokenSymbol, daysActive }: YieldTrackerProps) {
    const [yieldData, setYieldData] = useState({
        lpAmount: 0,
        reserveAmount: 0,
        yieldAccumulated: 0,
        projectedYield: 0,
        isActive: false,
    });

    useEffect(() => {
        // Calculate 80/20 split
        const lpAmount = totalAmount * 0.8;
        const reserveAmount = totalAmount * 0.2;

        // Simulate yield accumulation (0.1% per day as estimate)
        const dailyYieldRate = 0.001;
        // Ensure daysActive is positive and reasonable
        const validDaysActive = Math.max(0, Math.min(daysActive, 365)); // Cap at 1 year
        const yieldAccumulated = lpAmount * dailyYieldRate * validDaysActive;
        const projectedYield = lpAmount * dailyYieldRate * 21; // 21 day project

        setYieldData({
            lpAmount,
            reserveAmount,
            yieldAccumulated,
            projectedYield,
            isActive: true,
        });
    }, [totalAmount, daysActive]);

    if (!yieldData.isActive) {
        return null;
    }

    const freelancerYield = yieldData.yieldAccumulated * 0.7;
    const platformYield = yieldData.yieldAccumulated * 0.3;

    return (
        <Card className="border-emerald-500/20 bg-gradient-to-br from-emerald-500/5 to-transparent">
            <CardHeader>
                <div className="flex items-center justify-between">
                    <div>
                        <CardTitle className="text-lg flex items-center gap-2">
                            <Droplet className="h-5 w-5 text-emerald-500" />
                            Productive Capital
                        </CardTitle>
                        <CardDescription>
                            Your funds are earning yield in Uniswap V4
                        </CardDescription>
                    </div>
                    <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">
                        <Sparkles className="h-3 w-3 mr-1" />
                        Active
                    </Badge>
                </div>
            </CardHeader>
            <CardContent className="space-y-4">
                {/* LP Position */}
                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                        <p className="text-sm text-muted-foreground">LP Position</p>
                        <p className="text-2xl font-bold text-emerald-500">
                            {yieldData.lpAmount.toFixed(2)} {tokenSymbol}
                        </p>
                        <p className="text-xs text-muted-foreground">80% in liquidity pool</p>
                    </div>
                    <div className="space-y-1">
                        <p className="text-sm text-muted-foreground">Reserve</p>
                        <p className="text-2xl font-bold">
                            {yieldData.reserveAmount.toFixed(2)} {tokenSymbol}
                        </p>
                        <p className="text-xs text-muted-foreground">20% for payouts</p>
                    </div>
                </div>

                {/* Yield Stats */}
                <div className="pt-4 border-t">
                    <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                            <TrendingUp className="h-4 w-4 text-emerald-500" />
                            <span className="text-sm font-medium">Yield Earned</span>
                        </div>
                        <span className="text-lg font-bold text-emerald-500">
                            +{yieldData.yieldAccumulated.toFixed(4)} {tokenSymbol}
                        </span>
                    </div>

                    {/* Distribution Breakdown */}
                    <div className="space-y-2 mt-3 p-3 bg-muted/50 rounded-lg">
                        <p className="text-xs font-medium text-muted-foreground">Distribution (on milestone approval):</p>
                        <div className="flex items-center justify-between text-sm">
                            <span className="flex items-center gap-1">
                                <Coins className="h-3 w-3" />
                                Freelancer (70%)
                            </span>
                            <span className="font-semibold">+{freelancerYield.toFixed(4)} {tokenSymbol}</span>
                        </div>
                        <div className="flex items-center justify-between text-sm text-muted-foreground">
                            <span>Platform (30%)</span>
                            <span>{platformYield.toFixed(4)} {tokenSymbol}</span>
                        </div>
                    </div>

                    {/* Projected */}
                    <div className="mt-3 p-2 bg-emerald-500/5 rounded border border-emerald-500/20">
                        <div className="flex items-center justify-between text-xs">
                            <span className="text-muted-foreground">Projected Total Yield:</span>
                            <span className="font-semibold text-emerald-500">
                                ~{yieldData.projectedYield.toFixed(4)} {tokenSymbol}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Active indicator */}
                <div className="flex items-center gap-2 text-xs text-muted-foreground pt-2">
                    <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span>Earning swap fees for {daysActive} days</span>
                </div>
            </CardContent>
        </Card>
    );
}
