import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useWeb3 } from "@/contexts/web3-context";
import { Copy, ExternalLink, LogOut, RefreshCw, Wallet } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

export function WalletButton() {
  const { wallet, connectWallet, disconnectWallet, refreshBalance } = useWeb3();
  const { address, isConnected, balance } = wallet;
  const { toast } = useToast();

  const handleConnect = () => {
    void connectWallet();
  };

  const handleDisconnect = () => {
    disconnectWallet();
  };

  const handleCopyAddress = async () => {
    if (address) {
      await navigator.clipboard.writeText(address);
      toast({
        title: "Address copied",
        description: "Wallet address copied to clipboard",
      });
    }
  };

  const handleRefreshBalance = async () => {
    toast({
      title: "Refreshing balance...",
      description: "Fetching latest balance from Unichain",
    });
    await refreshBalance();
  };

  const handleViewOnExplorer = () => {
    if (address) {
      window.open(`https://unichain-sepolia.blockscout.com/address/${address}`, '_blank');
    }
  };

  if (!isConnected || !address) {
    return (
      <Button
        onClick={() => {
          void handleConnect();
        }}
        variant="default"
        className="relative"
      >
        Connect Wallet
      </Button>
    );
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="secondary"
          className="font-mono flex items-center gap-2 px-3 md:px-4 py-2 bg-muted/50 hover:bg-muted/70 border border-border/40 max-w-[160px] md:max-w-none"
        >
          {/* Desktop/tablet: show network + balance + avatar */}
          <div className="hidden md:flex items-center gap-2">
            <Wallet className="w-4 h-4 text-primary" />

            <span className={balance === "0" ? "text-yellow-500" : ""}>{Number(balance || 0).toFixed(4)} ETH</span>
            <span className="text-muted-foreground">·</span>

            {/* Address */}
            <span className="truncate max-w-[100px]">
              {address.slice(0, 5)}...{address.slice(-5)}
            </span>
          </div>

          {/* Mobile: just show address */}
          <div className="md:hidden flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
            <span className="truncate max-w-[80px]">
              {address.slice(0, 4)}...
            </span>
          </div>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <div className="px-2 py-1.5 text-sm font-semibold text-muted-foreground flex items-center justify-between">
          <span>My Wallet</span>
          <div className="flex items-center gap-1">
             <span className="text-xs bg-primary/10 text-primary px-1.5 py-0.5 rounded">
               Unichain Sepolia
             </span>
          </div>
        </div>
        <DropdownMenuSeparator />
        
        <DropdownMenuItem onClick={handleCopyAddress} className="cursor-pointer">
          <Copy className="mr-2 h-4 w-4" />
          <span>Copy Address</span>
        </DropdownMenuItem>
        
        <DropdownMenuItem onClick={handleRefreshBalance} className="cursor-pointer">
          <RefreshCw className="mr-2 h-4 w-4" />
          <span>Refresh Balance</span>
        </DropdownMenuItem>
        
        <DropdownMenuItem onClick={handleViewOnExplorer} className="cursor-pointer">
          <ExternalLink className="mr-2 h-4 w-4" />
          <span>View on Explorer</span>
        </DropdownMenuItem>
        
        <DropdownMenuSeparator />
        
        <DropdownMenuItem 
          onClick={handleDisconnect}
          className="cursor-pointer text-destructive focus:text-destructive"
        >
          <LogOut className="mr-2 h-4 w-4" />
          <span>Disconnect</span>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
