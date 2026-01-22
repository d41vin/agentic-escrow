// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ConditionalPayment.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Simple mock USDC for testing (6 decimals like real USDC)
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title ConditionalPaymentTest
 * @notice Tests for the core happy path: create → accept → submit → verify → release
 */
contract ConditionalPaymentTest is Test {
    ConditionalPayment public escrow;
    MockUSDC public usdc;

    address public principal = makeAddr("principal");
    address public worker = makeAddr("worker");
    address public verifier = makeAddr("verifier");

    uint256 constant AMOUNT = 100 * 1e6; // 100 USDC
    bytes32 constant CONDITION_HASH = keccak256("Deliver a working website");
    bytes32 constant PROOF_HASH = keccak256("Here is the proof of completion");

    function setUp() public {
        // Deploy mock USDC
        usdc = new MockUSDC();

        // Deploy escrow contract
        escrow = new ConditionalPayment(address(usdc));

        // Fund principal with USDC
        usdc.mint(principal, AMOUNT * 10);

        // Principal approves escrow
        vm.prank(principal);
        usdc.approve(address(escrow), type(uint256).max);
    }

    // ============ Happy Path Tests ============

    function test_CreatePayment() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        assertEq(paymentId, 1);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(payment.principal, principal);
        assertEq(payment.worker, address(0));
        assertEq(payment.verifier, verifier);
        assertEq(payment.amount, AMOUNT);
        assertEq(payment.conditionHash, CONDITION_HASH);
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Created)
        );
        assertEq(payment.deadline, deadline);

        // Verify USDC transferred to escrow
        assertEq(usdc.balanceOf(address(escrow)), AMOUNT);
        assertEq(usdc.balanceOf(principal), AMOUNT * 10 - AMOUNT);
    }

    function test_AcceptPayment() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(payment.worker, worker);
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Accepted)
        );
    }

    function test_SubmitProof() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        vm.prank(worker);
        escrow.submitProof(paymentId, PROOF_HASH);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Submitted)
        );
    }

    function test_VerifyAndRelease() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 workerBalanceBefore = usdc.balanceOf(worker);

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        vm.prank(worker);
        escrow.submitProof(paymentId, PROOF_HASH);

        // Verifier approves
        vm.prank(verifier);
        escrow.verify(paymentId, true);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Released)
        );

        // Verify USDC transferred to worker
        assertEq(usdc.balanceOf(worker), workerBalanceBefore + AMOUNT);
        assertEq(usdc.balanceOf(address(escrow)), 0);
    }

    function test_VerifyReject_AllowsResubmit() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        vm.prank(worker);
        escrow.submitProof(paymentId, PROOF_HASH);

        // Verifier rejects
        vm.prank(verifier);
        escrow.verify(paymentId, false);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        // Status should be back to Accepted, allowing resubmission
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Accepted)
        );

        // Worker can resubmit
        bytes32 newProofHash = keccak256("Here is the updated proof");
        vm.prank(worker);
        escrow.submitProof(paymentId, newProofHash);

        payment = escrow.getPayment(paymentId);
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Submitted)
        );
    }

    function test_CancelPayment() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 principalBalanceBefore = usdc.balanceOf(principal);

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        assertEq(usdc.balanceOf(principal), principalBalanceBefore - AMOUNT);

        vm.prank(principal);
        escrow.cancelPayment(paymentId);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Refunded)
        );

        // Principal gets refund
        assertEq(usdc.balanceOf(principal), principalBalanceBefore);
    }

    function test_RefundOnTimeout() public {
        uint256 deadline = block.timestamp + 7 days;
        uint256 principalBalanceBefore = usdc.balanceOf(principal);

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        // Fast forward past deadline
        vm.warp(deadline + 1);

        // Anyone can trigger refund
        escrow.refundOnTimeout(paymentId);

        ConditionalPayment.Payment memory payment = escrow.getPayment(
            paymentId
        );
        assertEq(
            uint256(payment.status),
            uint256(ConditionalPayment.PaymentStatus.Refunded)
        );

        // Principal gets refund
        assertEq(usdc.balanceOf(principal), principalBalanceBefore);
    }

    // ============ Access Control Tests ============

    function test_RevertWhen_NonWorkerSubmitsProof() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        // Someone else tries to submit proof
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert(ConditionalPayment.NotAuthorized.selector);
        escrow.submitProof(paymentId, PROOF_HASH);
    }

    function test_RevertWhen_NonVerifierVerifies() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        vm.prank(worker);
        escrow.submitProof(paymentId, PROOF_HASH);

        // Someone else tries to verify
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert(ConditionalPayment.NotAuthorized.selector);
        escrow.verify(paymentId, true);
    }

    function test_RevertWhen_NonPrincipalCancels() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        // Someone else tries to cancel
        vm.prank(worker);
        vm.expectRevert(ConditionalPayment.NotAuthorized.selector);
        escrow.cancelPayment(paymentId);
    }

    // ============ Edge Case Tests ============

    function test_RevertWhen_AcceptExpiredPayment() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        // Fast forward past deadline
        vm.warp(deadline + 1);

        vm.prank(worker);
        vm.expectRevert(ConditionalPayment.DeadlineExpired.selector);
        escrow.acceptPayment(paymentId);
    }

    function test_RevertWhen_RefundBeforeDeadline() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.expectRevert(ConditionalPayment.DeadlineNotExpired.selector);
        escrow.refundOnTimeout(paymentId);
    }

    function test_RevertWhen_CancelAfterAccepted() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        uint256 paymentId = escrow.createPayment(
            AMOUNT,
            CONDITION_HASH,
            verifier,
            deadline
        );

        vm.prank(worker);
        escrow.acceptPayment(paymentId);

        vm.prank(principal);
        vm.expectRevert(ConditionalPayment.InvalidStatus.selector);
        escrow.cancelPayment(paymentId);
    }

    function test_RevertWhen_ZeroAmount() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        vm.expectRevert(ConditionalPayment.InvalidAmount.selector);
        escrow.createPayment(0, CONDITION_HASH, verifier, deadline);
    }

    function test_RevertWhen_PastDeadline() public {
        uint256 pastDeadline = block.timestamp - 1;

        vm.prank(principal);
        vm.expectRevert(ConditionalPayment.InvalidDeadline.selector);
        escrow.createPayment(AMOUNT, CONDITION_HASH, verifier, pastDeadline);
    }

    function test_RevertWhen_ZeroVerifier() public {
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(principal);
        vm.expectRevert(ConditionalPayment.InvalidAddress.selector);
        escrow.createPayment(AMOUNT, CONDITION_HASH, address(0), deadline);
    }
}
