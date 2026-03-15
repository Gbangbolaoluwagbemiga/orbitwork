import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Web3Provider } from "@/contexts/web3-context";
import { NotificationProvider } from "@/contexts/notification-context";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/toaster";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "OrbitWork | Yield-Bearing Escrow",
  description: "The world's first yield-bearing escrow platform on Uniswap v4.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          <Web3Provider>
            <NotificationProvider>
              {children}
              <Toaster />
            </NotificationProvider>
          </Web3Provider>
        </ThemeProvider>
      </body>
    </html>
  );
}
