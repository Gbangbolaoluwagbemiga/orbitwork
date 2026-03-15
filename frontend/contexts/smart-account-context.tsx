"use client";
import React, { createContext, useContext } from 'react';

const SmartAccountContext = createContext<any>(null);

export const SmartAccountProvider = ({ children }: { children: React.ReactNode }) => {
  const value = {
    isSmartAccountReady: false,
    executeTransaction: async () => { throw new Error("Smart Account not implemented"); },
    executeBatchTransaction: async () => { throw new Error("Smart Account not implemented"); },
  };
  return (
    <SmartAccountContext.Provider value={value}>
      {children}
    </SmartAccountContext.Provider>
  );
};

export const useSmartAccount = () => {
  const context = useContext(SmartAccountContext);
  if (context === undefined || context === null) {
    // Return a safe default instead of throwing to prevent build issues in components that use it
    return {
      isSmartAccountReady: false,
      executeTransaction: async () => { throw new Error("Smart Account not implemented"); },
      executeBatchTransaction: async () => { throw new Error("Smart Account not implemented"); },
    };
  }
  return context;
};
