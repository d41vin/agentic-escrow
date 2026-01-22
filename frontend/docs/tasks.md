# Conduit Protocol - Task Breakdown

A granular task list for building Conduit Protocol. Each task is the smallest possible unit of work.

---

## Phase 0: Project Setup & Configuration

### 0.1 Repository Organization
- [ ] Create `sdk/` directory at root level
- [ ] Create `convex/` directory at root level (if not exists)
- [ ] Verify `frontend/docs/` contains `available-env.md` and `dev-circle-llms.txt`
- [ ] Create `frontend/.env.local.example` with documented variables

### 0.2 Install Dependencies
- [ ] Install frontend base dependencies: `pnpm install`
- [ ] Install Clerk auth: `pnpm add @clerk/nextjs`
- [ ] Install Convex: `pnpm add convex`
- [ ] Install AI SDK: `pnpm add ai @ai-sdk/google`
- [ ] Install Zod for validation: `pnpm add zod`
- [ ] Install ethers for blockchain: `pnpm add ethers@^6`
- [ ] Install Circle SDK: `pnpm add @circle-fin/developer-controlled-wallets`
- [ ] Install utilities: `pnpm add swr date-fns lucide-react`
- [ ] Verify contracts folder has OpenZeppelin: `forge install OpenZeppelin/openzeppelin-contracts`
- [ ] Create SDK package: `npm init -y` in `sdk/`
- [ ] Install SDK dependencies in `sdk/`

### 0.3 Environment Variables Setup
- [ ] Create `frontend/.env.local` with Clerk keys placeholder
- [ ] Add Convex URL placeholder to `.env.local`
- [ ] Add Gemini API keys placeholders (GEMINI_API_KEY_1, GEMINI_API_KEY_2)
- [ ] Add Circle credentials placeholders (CIRCLE_API_KEY, CIRCLE_ENTITY_SECRET, CIRCLE_WALLET_SET_ID)
- [ ] Add Arc blockchain config (RPC URL, contract address, USDC address)
- [ ] Add app URL configuration

### 0.4 Convex Setup
- [ ] Run `npx convex dev` and follow prompts to create project
- [ ] Copy Convex URL to `.env.local`
- [ ] Verify Convex dashboard accessible

### 0.5 Clerk Setup
- [ ] Create Clerk application at dashboard.clerk.com
- [ ] Copy publishable key to `.env.local`
- [ ] Copy secret key to `.env.local`
- [ ] Enable Google OAuth provider in Clerk dashboard
- [ ] Set up sign-in/sign-up URLs

---

## Phase 1: Smart Contracts (Foundation)

### 1.1 Smart Contract Architecture
- [ ] Create `contracts/src/ConditionalPayment.sol` file
- [ ] Import OpenZeppelin IERC20
- [ ] Import OpenZeppelin ReentrancyGuard
- [ ] Import OpenZeppelin Ownable
- [ ] Define PaymentStatus enum (Created, Accepted, Submitted, Verified, Released, Rejected, Cancelled, TimedOut)
- [ ] Define Payment struct with all fields
- [ ] Define state variables (usdc, paymentCounter, payments mapping)
- [ ] Define all events (PaymentCreated, PaymentAccepted, ProofSubmitted, Verified, PaymentReleased, PaymentCancelled, PaymentTimedOut)
- [ ] Implement constructor accepting USDC address
- [ ] Implement `createPayment` function
- [ ] Implement `acceptPayment` function
- [ ] Implement `submitProof` function
- [ ] Implement `verify` function
- [ ] Implement `releasePayment` function
- [ ] Implement `cancelPayment` function
- [ ] Implement `refundOnTimeout` function
- [ ] Implement `getPayment` view function
- [ ] Implement `getPaymentsByPrincipal` view function
- [ ] Implement `getPaymentsByWorker` view function
- [ ] Implement `getPaymentsByStatus` view function

### 1.2 Comprehensive Tests
- [ ] Create `contracts/test/ConditionalPayment.t.sol`
- [ ] Write test: Payment creation with USDC approval
- [ ] Write test: Worker acceptance
- [ ] Write test: Proof submission
- [ ] Write test: Verification approve flow
- [ ] Write test: Verification reject flow
- [ ] Write test: Payment release
- [ ] Write test: Cancellation before acceptance
- [ ] Write test: Timeout refund
- [ ] Write test: Access control - only verifier can verify
- [ ] Write test: Invalid state transitions
- [ ] Write test: Reentrancy protection
- [ ] Write test: Edge cases (zero amount, invalid addresses)
- [ ] Run `forge test -vvv` and achieve 100% pass

### 1.3 Deployment Script
- [ ] Create `contracts/script/Deploy.s.sol`
- [ ] Add Arc testnet configuration
- [ ] Add deployment logic for ConditionalPayment
- [ ] Add verification script

### 1.4 Deploy to Arc Testnet
- [ ] Set up private key for deployment
- [ ] Run deployment script: `forge script script/Deploy.s.sol --rpc-url https://testnet-rpc.arc.network --broadcast`
- [ ] Verify contract on Arc explorer
- [ ] Document deployed contract address in `.env.local`
- [ ] Test contract interaction via `cast`

---

## Phase 2: SDK Development

### 2.1 SDK Package Setup
- [ ] Create `sdk/package.json` with name `@d41vin/conditional-payment-sdk`
- [ ] Create `sdk/tsconfig.json` with TypeScript config
- [ ] Install ethers@^6 in SDK
- [ ] Install Circle SDK in SDK
- [ ] Install TypeScript dev dependencies

### 2.2 Core SDK Implementation
- [ ] Create `sdk/src/index.ts` with exports
- [ ] Create `sdk/src/types.ts` with all TypeScript interfaces
- [ ] Define Payment interface
- [ ] Define PaymentStatus enum
- [ ] Define CreatePaymentParams interface
- [ ] Define SDKConfig interface
- [ ] Define all event types
- [ ] Create `sdk/src/ConditionalPaymentSDK.ts`
- [ ] Implement constructor with provider, contract, wallet client setup
- [ ] Implement `createPayment` method
- [ ] Implement `acceptPayment` method
- [ ] Implement `submitProof` method
- [ ] Implement `verify` method
- [ ] Implement `releasePayment` method
- [ ] Implement `cancelPayment` method
- [ ] Implement `refundOnTimeout` method
- [ ] Implement `getPayment` method
- [ ] Implement `listPayments` method
- [ ] Implement `getPaymentsByPrincipal` method
- [ ] Implement `getPaymentsByWorker` method
- [ ] Implement `getPaymentsByStatus` method
- [ ] Implement event listeners (onPaymentCreated, onProofSubmitted, onVerified, onPaymentReleased)

### 2.3 Circle Wallet Integration
- [ ] Create `sdk/src/wallet.ts`
- [ ] Implement WalletManager class
- [ ] Implement `createUserWallet` method
- [ ] Implement `createAgentWallet` method
- [ ] Implement `getWallet` method
- [ ] Implement `signTransaction` method
- [ ] Implement `getBalance` method

### 2.4 SDK Build & Export
- [ ] Add contract ABI to SDK
- [ ] Run `npm run build` to compile SDK
- [ ] Verify `dist/` output exists
- [ ] Test importing SDK in frontend

---

## Phase 3: Backend Infrastructure (Convex)

### 3.1 Convex Schema
- [ ] Create `convex/schema.ts`
- [ ] Define `users` table with all fields and indexes
- [ ] Define `agents` table with policies object and indexes
- [ ] Define `payments` table with all fields and indexes
- [ ] Define `proofs` table with storageId support
- [ ] Define `verifications` table
- [ ] Define `agentActivity` table
- [ ] Deploy schema: `npx convex dev`

### 3.2 User Management Functions
- [ ] Create `convex/users.ts`
- [ ] Implement `createFromClerk` mutation for webhook
- [ ] Implement `getCurrent` query using auth identity
- [ ] Implement `getByWalletAddress` query
- [ ] Implement `getByClerkId` query

### 3.3 Payment Management Functions
- [ ] Create `convex/payments.ts`
- [ ] Implement `create` mutation
- [ ] Implement `list` query with filters (status, principal, worker)
- [ ] Implement `get` query by paymentId
- [ ] Implement `updateStatus` mutation
- [ ] Implement `getByPrincipal` query
- [ ] Implement `getByWorker` query

### 3.4 Agent Management Functions
- [ ] Create `convex/agents.ts`
- [ ] Implement API key generation utility
- [ ] Implement API key hashing utility
- [ ] Implement `create` mutation (returns API key once)
- [ ] Implement `listByOwner` query
- [ ] Implement `getByApiKey` query
- [ ] Implement `get` query by agentId
- [ ] Implement `update` mutation for policies
- [ ] Implement `toggleActive` mutation

### 3.5 Proof Management Functions
- [ ] Create `convex/proofs.ts`
- [ ] Implement `create` mutation
- [ ] Implement `get` query by paymentId
- [ ] Implement file storage URL generation

### 3.6 Verification Functions
- [ ] Create `convex/verifications.ts`
- [ ] Implement `create` mutation
- [ ] Implement `getByPaymentId` query

### 3.7 Activity Logging Functions
- [ ] Create `convex/agentActivity.ts`
- [ ] Implement `log` mutation
- [ ] Implement `getAgentActivity` query with limit

### 3.8 File Storage Functions
- [ ] Create `convex/files.ts`
- [ ] Implement `generateUploadUrl` mutation
- [ ] Implement `getUrl` query by storageId

---

## Phase 4: AI Verification System

### 4.1 Gemini Client with Key Rotation
- [ ] Create `frontend/lib/gemini-client.ts`
- [ ] Load Gemini API keys from environment
- [ ] Implement GeminiClientPool class
- [ ] Implement key rotation logic
- [ ] Implement `generateWithRetry` method
- [ ] Implement rate limit detection and retry
- [ ] Implement error tracking per key
- [ ] Implement `getStats` method

### 4.2 AI Verifier with Vercel AI SDK
- [ ] Create `frontend/lib/ai-verifier.ts`
- [ ] Define verification Zod schema (approved, confidence, reason, issues)
- [ ] Implement key rotation for Vercel AI SDK
- [ ] Implement `verifyProof` function for text proofs
- [ ] Implement multimodal verification for images
- [ ] Implement document verification support
- [ ] Add structured output with JSON schema

### 4.3 Verification API Endpoint
- [ ] Create `frontend/app/api/verify/route.ts`
- [ ] Implement POST handler
- [ ] Fetch payment details from Convex
- [ ] Fetch submitted proof from Convex
- [ ] Get proof data (from storage or text)
- [ ] Call `verifyProof` function
- [ ] Submit verification to smart contract via SDK
- [ ] Store verification result in Convex
- [ ] Update payment status in Convex
- [ ] Return verification result

### 4.4 Event Listener for Auto-Verification
- [ ] Create `frontend/lib/blockchain-listener.ts`
- [ ] Set up ethers provider with Arc RPC
- [ ] Load contract ABI and address
- [ ] Implement ProofSubmitted event listener
- [ ] Trigger verification API on proof submission
- [ ] Implement PaymentCreated event listener for sync
- [ ] Add error handling and logging
- [ ] Configure for production vs development

### 4.5 Gemini Stats API
- [ ] Create `frontend/app/api/admin/gemini-stats/route.ts`
- [ ] Return key usage and error stats

---

## Phase 5: Frontend Core (Auth + Basic UI)

### 5.1 Clerk Integration
- [ ] Create `frontend/components/providers/convex-provider.tsx`
- [ ] Set up ConvexReactClient with auth
- [ ] Update `frontend/app/layout.tsx` with ClerkProvider
- [ ] Wrap with ConvexClientProvider
- [ ] Add global styles import

### 5.2 Auth Pages
- [ ] Create `frontend/app/sign-in/[[...sign-in]]/page.tsx`
- [ ] Create `frontend/app/sign-up/[[...sign-up]]/page.tsx`
- [ ] Style auth pages with centered layout

### 5.3 Protected Route Middleware
- [ ] Create `frontend/middleware.ts`
- [ ] Configure public routes (/, /sign-in, /sign-up)
- [ ] Configure ignored routes for agent API
- [ ] Set up route matcher pattern

### 5.4 Clerk Webhook for User Creation
- [ ] Create `frontend/app/api/webhooks/clerk/route.ts`
- [ ] Implement webhook signature verification using svix
- [ ] Handle `user.created` event
- [ ] Create user in Convex with Circle Wallet
- [ ] Add CLERK_WEBHOOK_SECRET to environment

### 5.5 Landing Page
- [ ] Create `frontend/app/page.tsx`
- [ ] Add header with nav and auth buttons
- [ ] Add hero section with value proposition
- [ ] Add feature cards (Human-to-Human, Agent-to-Agent, Hybrid)
- [ ] Add CTA button

### 5.6 Dashboard Layout
- [ ] Create `frontend/app/dashboard/layout.tsx`
- [ ] Add authentication check with redirect
- [ ] Create `frontend/components/dashboard/sidebar.tsx`
- [ ] Add navigation routes (Overview, Create Payment, My Payments, Marketplace, My Agents)
- [ ] Implement active route highlighting
- [ ] Create `frontend/components/dashboard/header.tsx`
- [ ] Show user info and wallet address
- [ ] Add UserButton from Clerk

### 5.7 Dashboard Overview Page
- [ ] Create `frontend/app/dashboard/page.tsx`
- [ ] Show user stats summary
- [ ] Show recent payments
- [ ] Show quick action buttons

---

## Phase 6: Payment Features (Core Functionality)

### 6.1 Create Payment Page
- [ ] Create `frontend/app/dashboard/payments/create/page.tsx`
- [ ] Add amount input field
- [ ] Add condition textarea
- [ ] Add deadline datetime picker
- [ ] Add payment summary preview
- [ ] Implement form submission to API
- [ ] Add loading state
- [ ] Redirect to payment detail on success

### 6.2 Payment Creation API
- [ ] Create `frontend/app/api/payments/create/route.ts`
- [ ] Verify authentication
- [ ] Get user's wallet from Convex
- [ ] Hash condition with sha256
- [ ] Initialize SDK
- [ ] Create payment on blockchain
- [ ] Store payment in Convex
- [ ] Return payment ID

### 6.3 Payment Accept API
- [ ] Create `frontend/app/api/payments/accept/route.ts`
- [ ] Verify authentication
- [ ] Get user's wallet
- [ ] Call SDK.acceptPayment
- [ ] Update payment status in Convex

### 6.4 Payment List Page
- [ ] Create `frontend/app/dashboard/payments/page.tsx`
- [ ] Query payments by principal
- [ ] Create `frontend/components/payments/payment-card.tsx`
- [ ] Display payment ID, amount, status
- [ ] Display condition preview
- [ ] Display created date and deadline
- [ ] Link to payment detail

### 6.5 Marketplace Page
- [ ] Create `frontend/app/dashboard/marketplace/page.tsx`
- [ ] Query payments with status 'Created'
- [ ] Create `frontend/components/marketplace/marketplace-card.tsx`
- [ ] Display job details and amount
- [ ] Add Accept Job button
- [ ] Implement accept handler with API call
- [ ] Add loading state

### 6.6 Payment Detail Page
- [ ] Create `frontend/app/dashboard/payments/[id]/page.tsx`
- [ ] Query payment by ID
- [ ] Query verification result
- [ ] Display payment header (ID, status, amount)
- [ ] Display condition card
- [ ] Display details card (principal, worker, verifier, deadline)
- [ ] Create `frontend/components/payments/payment-timeline.tsx`
- [ ] Display verification result if exists

### 6.7 Submit Proof Form
- [ ] Create `frontend/components/payments/submit-proof-form.tsx`
- [ ] Add proof type selector (text, image, document)
- [ ] Add text input for text proofs
- [ ] Add file upload for images/documents
- [ ] Implement proof submission to API
- [ ] Show only when user is worker and status is Accepted

### 6.8 Submit Proof API
- [ ] Create `frontend/app/api/payments/submit-proof/route.ts`
- [ ] Verify authentication
- [ ] Handle file upload to Convex storage
- [ ] Hash proof content
- [ ] Call SDK.submitProof
- [ ] Store proof in Convex
- [ ] Update payment status

---

## Phase 7: Agent Dashboard

### 7.1 Create Agent Page
- [ ] Create `frontend/app/dashboard/agents/create/page.tsx`
- [ ] Add agent name input
- [ ] Add agent type selector (worker/buyer)
- [ ] Add min payment input
- [ ] Add max payment input
- [ ] Add daily limit input
- [ ] Add auto-accept toggle
- [ ] Implement create handler
- [ ] Display API key on success (show once)
- [ ] Add warning about saving API key

### 7.2 Agent List Page
- [ ] Create `frontend/app/dashboard/agents/page.tsx`
- [ ] Query agents by owner
- [ ] Add Create Agent button
- [ ] Create `frontend/components/agents/agent-card.tsx`
- [ ] Display agent name, type, status
- [ ] Display wallet address (truncated)
- [ ] Display policy summary

### 7.3 Agent Detail Page
- [ ] Create `frontend/app/dashboard/agents/[id]/page.tsx`
- [ ] Query agent by ID
- [ ] Query agent activity
- [ ] Display wallet and API info card
- [ ] Display policies card
- [ ] Add Configure button
- [ ] Create `frontend/components/agents/activity-feed.tsx`
- [ ] Display activity feed with formatted actions

### 7.4 Agent API Routes - Create Payment
- [ ] Create `frontend/app/api/agent/create-payment/route.ts`
- [ ] Validate API key from header
- [ ] Verify agent exists
- [ ] Check policy limits
- [ ] Create payment via SDK
- [ ] Store in Convex
- [ ] Log activity

### 7.5 Agent API Routes - Accept Payment
- [ ] Create `frontend/app/api/agent/accept-payment/route.ts`
- [ ] Validate API key
- [ ] Check policy limits
- [ ] Accept payment via SDK
- [ ] Update Convex
- [ ] Log activity

### 7.6 Agent API Routes - Submit Proof
- [ ] Create `frontend/app/api/agent/submit-proof/route.ts`
- [ ] Validate API key
- [ ] Submit proof via SDK
- [ ] Store proof in Convex
- [ ] Log activity

### 7.7 Agent API Routes - List Payments
- [ ] Create `frontend/app/api/agent/list-payments/route.ts`
- [ ] Validate API key
- [ ] Query available payments
- [ ] Return filtered list

---

## Phase 8: Integration & Testing

### 8.1 End-to-End Flow Testing
- [ ] Test: Human creates payment → Worker accepts → Submits proof → AI verifies → Payment released
- [ ] Test: Agent creates payment (via API) → Human accepts → Submits proof → Verified → Released
- [ ] Test: Human creates payment → Agent accepts (via API) → Agent submits → Verified → Released
- [ ] Test: Agent creates payment → Agent accepts → Agent submits → Verified → Released

### 8.2 Circle Wallet Integration Testing
- [ ] Test: User signup creates Circle Wallet
- [ ] Test: Agent creation creates Circle Wallet
- [ ] Test: USDC transfers work correctly
- [ ] Test: Gas fees (in USDC) handled properly
- [ ] Test: Wallet balances update in real-time

### 8.3 Blockchain Event Listener Testing
- [ ] Test: ProofSubmitted event triggers verification
- [ ] Test: PaymentCreated syncs to Convex
- [ ] Test: PaymentReleased updates UI

### 8.4 Error Handling & Edge Cases
- [ ] Test: Insufficient USDC balance
- [ ] Test: Expired deadlines (timeout refund)
- [ ] Test: Invalid proof submission
- [ ] Test: AI verification errors
- [ ] Test: Network failures
- [ ] Test: Concurrent requests

### 8.5 Performance Optimization
- [ ] Optimize Convex queries with indexes
- [ ] Add loading states everywhere
- [ ] Implement optimistic updates
- [ ] Cache frequently accessed data

### 8.6 Security Audit
- [ ] Verify API key hashing (not storing plain text)
- [ ] Verify input validation on all endpoints
- [ ] Add rate limiting on public endpoints
- [ ] Configure CORS properly
- [ ] Verify environment variables not exposed

---

## Phase 9: Polish & Demo Preparation

### 9.1 UI Polish
- [ ] Ensure consistent styling across all pages
- [ ] Add loading indicators everywhere
- [ ] Make error messages user-friendly
- [ ] Implement responsive design (mobile-friendly)
- [ ] Add animations/transitions for state changes
- [ ] Add empty states with helpful CTAs

### 9.2 Documentation
- [ ] Finalize README.md with all sections
- [ ] Add architecture diagram
- [ ] Document API endpoints
- [ ] Document SDK usage

### 9.3 Demo Video
- [ ] Record overview (30s) - What it is, why it matters
- [ ] Record human flow (60s) - Create → Accept → Submit → Verify → Release
- [ ] Record agent flow (60s) - Agent dashboard → API call → Auto-fulfillment
- [ ] Record transaction proof (30s) - Show on Circle Console + Arc Explorer
- [ ] Record key features (60s) - Multi-modal verification, policies, logs
- [ ] Record closing (30s) - Built on Arc, USDC, Circle, Gemini

### 9.4 Screenshots
- [ ] Capture landing page
- [ ] Capture dashboard overview
- [ ] Capture create payment form
- [ ] Capture payment marketplace
- [ ] Capture agent dashboard
- [ ] Capture verification result
- [ ] Capture transaction on Arc Explorer

### 9.5 Circle Product Feedback
- [ ] Write products used section
- [ ] Write what worked well section
- [ ] Write challenges encountered section
- [ ] Write recommendations section

### 9.6 Test Data Preparation
- [ ] Create 5-10 demo payments in various states
- [ ] Create 2-3 demo agents with activity
- [ ] Create sample verifications with different outcomes
- [ ] Populate marketplace with jobs

---

## Phase 10: Submission

### 10.1 Final Checklist
- [ ] All required fields in lablab.ai submission form
- [ ] Project title compelling
- [ ] Short description (1-2 sentences)
- [ ] Long description (detailed)
- [ ] Cover image uploaded
- [ ] Demo video uploaded
- [ ] Slide presentation (optional)
- [ ] GitHub repo public
- [ ] Application URL (deployed on Vercel)
- [ ] Transaction flow demonstration in video
- [ ] Circle Product Feedback included

### 10.2 Deploy to Production
- [ ] Deploy frontend to Vercel: `vercel --prod`
- [ ] Deploy Convex to production: `pnpx convex deploy --prod`
- [ ] Set all environment variables on Vercel

### 10.3 GitHub Repo Cleanup
- [ ] Add proper .gitignore
- [ ] Clean commit history
- [ ] Add LICENSE file (MIT)
- [ ] Ensure README is at root

### 10.4 Test Deployed Version
- [ ] All features work on production URL
- [ ] No console errors
- [ ] Environment variables set correctly
- [ ] Wallet connections work
- [ ] Transactions execute on Arc testnet

### 10.5 Submit on lablab.ai
- [ ] Go to hackathon page
- [ ] Click "Submit Project"
- [ ] Fill all required fields
- [ ] Double-check everything
- [ ] Submit before deadline!

---

## Notes

- **Package Manager**: Use `pnpm` for all frontend operations
- **Commits**: Use conventional commit messages with description, commit and push after each task or logical group
- **Development Mode**: Run `npx convex dev` in one terminal, `pnpm dev` in another
- **Testing**: Test each phase before moving to the next
