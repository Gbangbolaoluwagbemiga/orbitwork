"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingUp, Droplet, DollarSign, Zap } from "lucide-react";

interface ProductiveCapitalStatsProps {
    totalEscrowed: number;
    totalInLP: number;
    totalYieldEarned: number;
    tokenSymbol: string;
}

export function ProductiveCapitalStats({
    totalEscrowed,
    totalInLP,
    totalYieldEarned,
    tokenSymbol,
}: ProductiveCapitalStatsProps) {
    const lpRatio = totalEscrowed > 0 ? (totalInLP / totalEscrowed) * 100 : 0;
    const yieldAPR = totalInLP > 0 ? (totalYieldEarned / totalInLP) * 100 : 0;

    return (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {/* Total Escrowed */}
            <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Escrowed</CardTitle>
                    <DollarSign className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                    <div className="text-2xl font-bold">
                        {totalEscrowed.toFixed(2)} {tokenSymbol}
                    </div>
                    <p className="text-xs text-muted-foreground">Across all active escrows</p>
                </CardContent>
            </Card>

            {/* Productive Capital */}
            <Card className="border-emerald-500/20">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Productive Capital</CardTitle>
                    <Droplet className="h-4 w-4 text-emerald-500" />
                </CardHeader>
                <CardContent>
                    <div className="text-2xl font-bold text-emerald-500">
                        {totalInLP.toFixed(2)} {tokenSymbol}
                    </div>
                    <p className="text-xs text-muted-foreground">
                        {lpRatio.toFixed(1)}% in Uniswap V4 LP
                    </p>
                </CardContent>
            </Card>

            {/* Total Yield */}
            <Card className="border-amber-500/20">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Yield Earned</CardTitle>
                    <TrendingUp className="h-4 w-4 text-amber-500" />
                </CardHeader>
                <CardContent>
                    <div className="text-2xl font-bold text-amber-500">
                        +{totalYieldEarned.toFixed(4)} {tokenSymbol}
                    </div>
                    <p className="text-xs text-muted-foreground">From swap fees</p>
                </CardContent>
            </Card>

            {/* APR */}
            <Card className="border-purple-500/20">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Current APR</CardTitle>
                    <Zap className="h-4 w-4 text-purple-500" />
                </CardHeader>
                <CardContent>
                    <div className="text-2xl font-bold text-purple-500">{yieldAPR.toFixed(2)}%</div>
                    <p className="text-xs text-muted-foreground">Annualized yield rate</p>
                </CardContent>
            </Card>
        </div>
    );
}
