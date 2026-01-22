// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ConditionalPayment
 * @notice A minimal escrow contract for conditional payments verified by an AI agent.
 * @dev Core flow: create → accept → submitProof → verify → release
 */
contract ConditionalPayment is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    uint256 public paymentCounter;

    enum PaymentStatus {
        Created, // Payment created, waiting for worker
        Accepted, // Worker accepted the job
        Submitted, // Proof submitted, waiting for verification
        Released, // Payment released to worker
        Refunded // Payment refunded to principal (cancelled or timed out)
    }

    struct Payment {
        uint256 id;
        address principal; // Who created and funded the payment
        address worker; // Who will fulfill the condition
        address verifier; // AI agent address that can verify
        uint256 amount; // USDC amount (6 decimals)
        bytes32 conditionHash; // Hash of the condition text (stored off-chain)
        PaymentStatus status;
        uint256 createdAt;
        uint256 deadline; // Unix timestamp when payment expires
    }

    mapping(uint256 => Payment) public payments;

    // Events for off-chain indexing
    event PaymentCreated(
        uint256 indexed paymentId,
        address indexed principal,
        address indexed verifier,
        uint256 amount,
        bytes32 conditionHash,
        uint256 deadline
    );
    event PaymentAccepted(uint256 indexed paymentId, address indexed worker);
    event ProofSubmitted(uint256 indexed paymentId, bytes32 proofHash);
    event PaymentVerified(uint256 indexed paymentId, bool approved);
    event PaymentReleased(
        uint256 indexed paymentId,
        address indexed worker,
        uint256 amount
    );
    event PaymentRefunded(
        uint256 indexed paymentId,
        address indexed principal,
        uint256 amount
    );

    error InvalidAmount();
    error InvalidDeadline();
    error InvalidAddress();
    error PaymentNotFound();
    error InvalidStatus();
    error NotAuthorized();
    error DeadlineExpired();
    error DeadlineNotExpired();

    constructor(address _usdc) {
        require(_usdc != address(0), "Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    /**
     * @notice Create a new conditional payment
     * @param amount USDC amount to escrow (6 decimals)
     * @param conditionHash Hash of the condition text
     * @param verifier Address of the AI verifier agent
     * @param deadline Unix timestamp when payment expires
     * @return paymentId The ID of the created payment
     */
    function createPayment(
        uint256 amount,
        bytes32 conditionHash,
        address verifier,
        uint256 deadline
    ) external nonReentrant returns (uint256 paymentId) {
        if (amount == 0) revert InvalidAmount();
        if (deadline <= block.timestamp) revert InvalidDeadline();
        if (verifier == address(0)) revert InvalidAddress();

        paymentId = ++paymentCounter;

        payments[paymentId] = Payment({
            id: paymentId,
            principal: msg.sender,
            worker: address(0),
            verifier: verifier,
            amount: amount,
            conditionHash: conditionHash,
            status: PaymentStatus.Created,
            createdAt: block.timestamp,
            deadline: deadline
        });

        // Transfer USDC from principal to this contract
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        emit PaymentCreated(
            paymentId,
            msg.sender,
            verifier,
            amount,
            conditionHash,
            deadline
        );
    }

    /**
     * @notice Accept a payment job as a worker
     * @param paymentId The payment to accept
     */
    function acceptPayment(uint256 paymentId) external nonReentrant {
        Payment storage payment = payments[paymentId];

        if (payment.id == 0) revert PaymentNotFound();
        if (payment.status != PaymentStatus.Created) revert InvalidStatus();
        if (block.timestamp >= payment.deadline) revert DeadlineExpired();

        payment.worker = msg.sender;
        payment.status = PaymentStatus.Accepted;

        emit PaymentAccepted(paymentId, msg.sender);
    }

    /**
     * @notice Submit proof of completion (triggers off-chain verification)
     * @param paymentId The payment ID
     * @param proofHash Hash of the proof data (actual data stored off-chain)
     */
    function submitProof(
        uint256 paymentId,
        bytes32 proofHash
    ) external nonReentrant {
        Payment storage payment = payments[paymentId];

        if (payment.id == 0) revert PaymentNotFound();
        if (payment.status != PaymentStatus.Accepted) revert InvalidStatus();
        if (msg.sender != payment.worker) revert NotAuthorized();
        if (block.timestamp >= payment.deadline) revert DeadlineExpired();

        payment.status = PaymentStatus.Submitted;

        emit ProofSubmitted(paymentId, proofHash);
    }

    /**
     * @notice Verify proof and release or reject payment (called by AI verifier)
     * @param paymentId The payment ID
     * @param approved Whether the proof is approved
     */
    function verify(uint256 paymentId, bool approved) external nonReentrant {
        Payment storage payment = payments[paymentId];

        if (payment.id == 0) revert PaymentNotFound();
        if (payment.status != PaymentStatus.Submitted) revert InvalidStatus();
        if (msg.sender != payment.verifier) revert NotAuthorized();

        emit PaymentVerified(paymentId, approved);

        if (approved) {
            payment.status = PaymentStatus.Released;
            usdc.safeTransfer(payment.worker, payment.amount);
            emit PaymentReleased(paymentId, payment.worker, payment.amount);
        } else {
            // On rejection, allow worker to resubmit (reset to Accepted)
            payment.status = PaymentStatus.Accepted;
        }
    }

    /**
     * @notice Cancel payment before it's accepted (principal only)
     * @param paymentId The payment ID
     */
    function cancelPayment(uint256 paymentId) external nonReentrant {
        Payment storage payment = payments[paymentId];

        if (payment.id == 0) revert PaymentNotFound();
        if (payment.status != PaymentStatus.Created) revert InvalidStatus();
        if (msg.sender != payment.principal) revert NotAuthorized();

        payment.status = PaymentStatus.Refunded;
        usdc.safeTransfer(payment.principal, payment.amount);

        emit PaymentRefunded(paymentId, payment.principal, payment.amount);
    }

    /**
     * @notice Refund payment after deadline expires (anyone can call)
     * @param paymentId The payment ID
     */
    function refundOnTimeout(uint256 paymentId) external nonReentrant {
        Payment storage payment = payments[paymentId];

        if (payment.id == 0) revert PaymentNotFound();
        // Can refund if still Created, Accepted, or Submitted (not Released or already Refunded)
        if (
            payment.status == PaymentStatus.Released ||
            payment.status == PaymentStatus.Refunded
        ) revert InvalidStatus();
        if (block.timestamp < payment.deadline) revert DeadlineNotExpired();

        payment.status = PaymentStatus.Refunded;
        usdc.safeTransfer(payment.principal, payment.amount);

        emit PaymentRefunded(paymentId, payment.principal, payment.amount);
    }

    /**
     * @notice Get payment details
     * @param paymentId The payment ID
     * @return The payment struct
     */
    function getPayment(
        uint256 paymentId
    ) external view returns (Payment memory) {
        if (payments[paymentId].id == 0) revert PaymentNotFound();
        return payments[paymentId];
    }
}
