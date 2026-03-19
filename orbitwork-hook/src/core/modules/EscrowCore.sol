// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "../interfaces/IOrbitWork.sol";

import "../interfaces/IEscrowHook.sol";

import "./OrbitWorkLib.sol";

abstract contract EscrowCore is ReentrancyGuard, Ownable, Pausable, IOrbitWork {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // Storage slot for OrbitWork protocol state
    // keccak256("orbitwork.storage.v1")
    bytes32 private constant STORAGE_SLOT = 0x5a1b3c9d7e8f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b;

    function _getLogicState() internal view returns (OrbitWorkLib.EscrowState storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    // ===== Constants =====
    uint256 public constant MIN_DURATION = 1 hours;
    uint256 public constant MAX_DURATION = 365 days;
    uint256 public constant DISPUTE_PERIOD = 7 days;
    uint256 public constant EMERGENCY_REFUND_DELAY = 30 days;
    uint256 public constant MAX_PLATFORM_FEE_BP = 1000; // 10%
    uint256 public constant MAX_ARBITERS = 5;
    uint256 public constant MAX_MILESTONES = 20;
    uint256 public constant MAX_APPLICATIONS = 50;
    uint256 public constant REPUTATION_PER_MILESTONE = 10;
    uint256 public constant REPUTATION_PER_ESCROW = 25;
    uint256 public constant MIN_REP_ELIGIBLE_ESCROW_VALUE = 1e16; // 0.01 native or token base units

    // version
    string public constant CONTRACT_VERSION = "1.0.0";

    // ===== Public Getters (ABI Compatibility) =====
    function orbitworkToken() public view returns (address) { return _getLogicState().orbitworkToken; }
    function platformFeeBP() public view returns (uint256) { return _getLogicState().platformFeeBP; }
    function feeCollector() public view returns (address) { return _getLogicState().feeCollector; }
    function jobCreationPaused() public view returns (bool) { return _getLogicState().jobCreationPaused; }
    function nextEscrowId() public view returns (uint256) { return _getLogicState().nextEscrowId; }
    function escrows(uint256 id) public view returns (EscrowData memory) { return _getLogicState().escrows[id]; }
    function milestones(uint256 id, uint256 idx) public view returns (Milestone memory) { return _getLogicState().milestones[id][idx]; }
    function userEscrows(address user, uint256 idx) public view returns (uint256) { return _getLogicState().userEscrows[user][idx]; }
    function authorizedArbiters(address arbiter) public view returns (bool) { return _getLogicState().authorizedArbiters[arbiter]; }
    function whitelistedTokens(address token) public view returns (bool) { return _getLogicState().whitelistedTokens[token]; }
    function escrowedAmount(address token) public view returns (uint256) { return _getLogicState().escrowedAmount[token]; }
    function totalFeesByToken(address token) public view returns (uint256) { return _getLogicState().totalFeesByToken[token]; }
    function hasApplied(uint256 id, address user) public view returns (bool) { return _getLogicState().hasApplied[id][user]; }
    function reputation(address user) public view returns (uint256) { return _getLogicState().reputation[user]; }
    function completedEscrows(address user) public view returns (uint256) { return _getLogicState().completedEscrows[user]; }
    function selfVerifiedUsers(address user) public view returns (bool) { return _getLogicState().selfVerifiedUsers[user]; }
    function verificationTimestamp(address user) public view returns (uint256) { return _getLogicState().verificationTimestamp[user]; }
    function escrowHook() public view returns (IEscrowHook) { return _getLogicState().escrowHook; }
    function liquidEscrowEnabled() public view returns (bool) { return _getLogicState().liquidEscrowEnabled; }
    function escrowPoolKeys(uint256 id) public view returns (IEscrowHook.PoolKey memory) { return _getLogicState().escrowPoolKeys[id]; }
    function escrowPoolParams(uint256 id) public view returns (IEscrowHook.ModifyLiquidityParams memory) { return _getLogicState().escrowPoolParams[id]; }
    function reactiveCallbackSender() public view returns (address) { return _getLogicState().reactiveCallbackSender; }

    // ===== Modifiers (Updated to use _getLogicState) =====
    modifier onlyEscrowParticipant(uint256 escrowId) {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[escrowId];
        bool isArv = false;
        for (uint256 i = 0; i < e.arbiters.length; i++) {
            if (e.arbiters[i] == msg.sender) {
                isArv = true;
                break;
            }
        }
        require(
            msg.sender == e.depositor || 
            msg.sender == e.beneficiary || 
            isArv,
            "participant"
        );
        _;
    }

    modifier onlyDepositor(uint256 escrowId) {
        require(msg.sender == _getLogicState().escrows[escrowId].depositor, "depositor");
        _;
    }

    modifier onlyBeneficiary(uint256 escrowId) {
        require(msg.sender == _getLogicState().escrows[escrowId].beneficiary, "beneficiary");
        _;
    }

    modifier onlyArbiter(uint256 escrowId) {
        bool found = false;
        address[] storage arbiters = _getLogicState().escrows[escrowId].arbiters;
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (arbiters[i] == msg.sender) {
                found = true;
                break;
            }
        }
        require(found, "arbiter");
        _;
    }

    modifier validEscrow(uint256 escrowId) {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        require(escrowId > 0 && escrowId < s.nextEscrowId, "id");
        _;
    }

    modifier onlyWhitelistedToken(address token) {
        require(token == address(0) || _getLogicState().whitelistedTokens[token], "token");
        _;
    }

    modifier onlyAuthorizedArbiter(address arbiter) {
        require(_getLogicState().authorizedArbiters[arbiter], "Arbiter not authorized");
        _;
    }

    modifier whenJobCreationNotPaused() {
        require(!_getLogicState().jobCreationPaused, "paused");
        _;
    }

    constructor(address _orbitworkToken, address _feeCollector, uint256 _platformFeeBP) Ownable(msg.sender) {
        require(_feeCollector != address(0), "feeCollector");
        require(_platformFeeBP <= MAX_PLATFORM_FEE_BP, "feeTooHigh");

        OrbitWorkLib.EscrowState storage s = _getLogicState();
        s.orbitworkToken = _orbitworkToken;
        s.feeCollector = _feeCollector;
        s.platformFeeBP = _platformFeeBP;
        s.nextEscrowId = 1;

        if (_orbitworkToken != address(0)) {
            s.whitelistedTokens[_orbitworkToken] = true;
            emit TokenWhitelisted(_orbitworkToken);
        }
    }

    // ===== Helper functions =====
    
    /**
     * @notice Calculate platform fee with discount for verified users
     * @param user Address of the user creating the escrow
     * @param amount Amount to calculate fee on
     * @return Platform fee amount (50% discount for verified users)
     */
    function calculatePlatformFee(address user, uint256 amount) public view returns (uint256) {
        if (platformFeeBP() == 0) return 0;
        
        uint256 baseFee = (amount * platformFeeBP()) / 10000;
        
        // 50% discount for Self Protocol verified users
        if (selfVerifiedUsers(user)) {
            return baseFee / 2;
        }
        
        return baseFee;
    }
    
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        if (platformFeeBP() == 0) return 0;
        return (amount * platformFeeBP()) / 10000;
    }

    function _transferIn(address token, address from, uint256 amount, bool isNative) internal {
        if (isNative) {
            return;
        } else {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }
    }

    function _transferOut(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok, ) = to.call{value: amount}("");
            require(ok, "Native transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _isArbiterForEscrow(uint256 escrowId, address arbiter) internal view returns (bool) {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[escrowId];
        for (uint256 i = 0; i < e.arbiters.length; ++i) {
            if (e.arbiters[i] == arbiter) return true;
        }
        return false;
    }

    function _updateReputation(address user, uint256 points, string memory reason) internal {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        // Only update reputation for verified users to prevent Sybil attacks
        if (user != address(0) && s.selfVerifiedUsers[user]) {
            s.reputation[user] += points;
            emit ReputationUpdated(user, s.reputation[user], reason);
        }
    }

    function isArbiterForEscrow(uint256 escrowId, address arbiter) external view validEscrow(escrowId) returns (bool) {
        return _isArbiterForEscrow(escrowId, arbiter);
    }

    receive() external payable {
        // Accept native tokens for hackathon demo
        // In production, this should be more restrictive
    }

    fallback() external payable {
        revert("Orbitwork: Fallback not allowed");
    }
}
