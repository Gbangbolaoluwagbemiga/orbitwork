export type EscrowStatus = 'pending' | 'active' | 'completed' | 'disputed' | 'refunded' | 'expired';
export type MilestoneStatus = 'pending' | 'submitted' | 'approved' | 'disputed' | 'resolved' | 'rejected';

export interface Milestone {
  description: string;
  amount: bigint;
  status: MilestoneStatus;
  submittedAt: number;
  approvedAt: number;
}

export interface Escrow {
  id: string;
  depositor: string;
  beneficiary: string;
  token: string;
  totalAmount: bigint;
  paidAmount: bigint;
  status: EscrowStatus;
  milestones: Milestone[];
  createdAt: number;
}
