# Teshio Protocol: Agreement Specification

**Status:** Design specification, not yet implemented or chain-verified  
**Target:** Gno testnet / GnoSwap  
**Version:** 0.3.0

## 1. Purpose and economic model

A GnoSwap liquidity position combines exposure to the underlying liquidity position with the right to collect swap fees. Teshio explores separating those rights for a defined agreement:

- The **principal claimant** retains the right to recover the same GnoSwap position NFT.
- The **fee claimant** purchases the right to actual net swap fees collected by Teshio during the agreement.
- Teshio holds the NFT in custody while the agreement is unresolved.

This is an experimental fee-right agreement. It is not a fixed-yield product. The position can earn zero fees and remains exposed to price movement, impermanent loss, range inactivity, GnoSwap changes, and other protocol risks.

## 2. Scope

The first implementation supports one unstaked GnoSwap position NFT, one principal claimant, one fee claimant, one asking price, and one fee-claim agreement per position.

Excluded: lending, leverage, liquidation, oracles, AMM/secondary trading, partial fee-right sales, multiple NFTs per agreement, staked positions, cross-chain assets, and guaranteed APR.

## 3. Agreement record

Each agreement must persist the following fields. Exact Gno types and timestamp representation must be confirmed against the target toolchain before implementation.

| Field | Purpose | Mutability |
|---|---|---|
| `AgreementID` | Unique Teshio agreement identifier | Immutable |
| `PositionID` | GnoSwap position NFT identifier | Immutable |
| `PrincipalClaimant` | Address entitled to recover the NFT | Immutable |
| `FeeClaimant` | Buyer address; empty until purchase | Set once |
| `PaymentTokenKey` | Registered token used for asking-price payment | Immutable |
| `AskingPrice` | Exact purchase consideration in base units | Immutable |
| `EarliestCloseTime` | Earliest time a normal close may execute | Immutable |
| `CreatedAt` | Agreement creation time | Immutable |
| `PurchasedAt` | Purchase time | Set once |
| `State` | Current lifecycle state | Controlled transitions only |
| `Token0Key`, `Token1Key` | Fee-token keys derived from the position pool key | Immutable after verification |
| `Claimable0`, `Claimable1` | Withdrawable net fee balances owed to fee claimant | Increase on successful collection; decrease on successful withdrawal |
| `TotalCollected0`, `TotalCollected1` | Cumulative actual net amounts credited | Increase on successful collection |
| `CollectionCount` | Successful collection count, for audit and replay checks | Increase on successful collection |
| `ClosedAt` | Time final collection succeeded | Set once on normal close |
| `RedeemedAt` | Time NFT was returned | Set once on redemption |
| `EmergencyPrincipalConsent` | Principal claimant's consent to the defined emergency exit | Set only by principal claimant |
| `EmergencyFeeConsent` | Fee claimant's consent to the same emergency exit | Set only by fee claimant |
| `EmergencyConsentVersion` | Version/hash of the exact exit terms both parties accepted | Set with each consent; must match |

The fee claimant's claimable balances are independent of NFT custody. A nonzero fee balance must never prevent principal redemption.

The agreement must also retain enough information to verify the exact NFT and token contracts at every external interaction. Never accept caller-supplied fee-token addresses as authoritative; derive token keys from the verified GnoSwap position pool key and validate registration.

## 4. Lifecycle states

### `Deposited`

The eligible NFT is held by Teshio. No fee claimant has purchased the fee right. The purchase terms are fixed.

### `Active`

The asking price has been paid and the fee claimant is recorded. Fee collection is permitted. The fee right remains active until a successful normal close or a mutually authorized emergency exit.

### `RecoveryPending`

GnoSwap's public `halt.IsHaltedWithdraw()` reports that withdrawal operations are halted. Teshio retains the NFT and does not treat estimates as collected fees. Existing claimable balances remain owed.

A failed cross-realm call that panics cannot itself be caught and followed by a state write in the same transaction. Therefore, Teshio must check the public halt getter before calling `CollectFee`. If it reports halted, Teshio may set `RecoveryPending` and return without calling `CollectFee`.

If the getter reports not halted but `CollectFee` unexpectedly panics, the whole transaction should abort and the agreement should remain in its prior state.

### `Closed`

The final GnoSwap fee collection succeeded and its actual net return amounts were credited. No further collection is permitted. Previously credited fee balances remain withdrawable.

### `Redeemed`

The NFT has been returned to the principal claimant. This is terminal. It can result from normal redemption after `Closed`, an unpurchased agreement cancellation, or a mutually authorized emergency exit from `RecoveryPending`. The exit reason must be stored separately so these cases remain distinguishable.

## 5. Allowed transitions and authorization

| From | To | Operation | Who may call | Required conditions |
|---|---|---|---|---|
| none | `Deposited` | Create and deposit | Principal claimant | Eligible unstaked NFT; caller owns it; approval exists; custody independently verified; no existing live agreement for position |
| `Deposited` | `Active` | Purchase | Any address except principal claimant | Exact asking price paid in registered payment token; payment transfer succeeds; fee claimant set once |
| `Deposited` | `Redeemed` | Cancel unpurchased agreement | Principal claimant | No fee claimant/payment; NFT still held by Teshio; transfer to recorded principal claimant succeeds |
| `Active` | `Active` | Collect fees | Anyone | Withdrawal halt getter is false; actual `CollectFee` succeeds; actual net return amounts credited exactly once |
| `Active` | `RecoveryPending` | Enter recovery | Anyone | Public `IsHaltedWithdraw()` returns true; no fee collection attempted in this call |
| `Active` | `Closed` | Normal close | Anyone | Earliest close time reached; halt getter false; final `CollectFee` succeeds; returned net amounts credited; state closes atomically |
| `RecoveryPending` | `Active` | Resume | Anyone | Withdrawal halt getter is false; earliest close time has not been reached; no emergency exit has completed |
| `RecoveryPending` | `Closed` | Retry normal close | Anyone | Earliest close time reached; halt getter false; final collection succeeds and is credited |
| `RecoveryPending` | `Redeemed` | Emergency exit | Anyone may execute | Both claimants separately consent to identical exit terms; withdrawal halt is still true; NFT transfer succeeds; uncollected fee rights are waived by both; already-credited balances remain owed |
| `Closed` | `Redeemed` | Redeem principal | Principal claimant | Final accounting complete; NFT owner is Teshio; transfer to principal claimant succeeds |

No other state transition is valid. In particular, there is no unilateral emergency exit, no fee collection after `Closed`, and no redemption from `Active`.

## 6. Purchase and payment

The principal claimant sets one asking price and one registered payment token before purchase. The purchase operation must:

1. Require state `Deposited`.
2. Reject the principal claimant as buyer.
3. Verify the payment token is registered and supported.
4. Transfer the exact asking price from buyer to principal claimant.
5. Record the fee claimant and purchase time.
6. Change state to `Active`.

If any step fails, the transaction must abort. Do not record `Active` or a fee claimant when payment has not completed. Purchase terms cannot be changed after creation; cancellation is available only before purchase.

## 7. Fee collection and accounting

For an active agreement:

1. Read GnoSwap's public withdrawal-halt status.
2. If halted, set `RecoveryPending` and return without calling `CollectFee`.
3. Otherwise call GnoSwap `CollectFee` as the NFT owner.
4. Use only the actual net token0 and token1 amounts returned by GnoSwap.
5. Increase `Claimable0/1` and `TotalCollected0/1` by those exact net amounts.
6. Increment `CollectionCount`.

Never credit `GetUnclaimedFee` estimates. They are not actual collected amounts and do not account for the final withdrawal fee. A zero-amount collection credits zero.

If any downstream call panics, do not recover and continue. The transaction must abort so external GnoSwap state and Teshio accounting cannot diverge. If a token-transfer API returns an error after prior state changes, panic rather than return normally.

## 8. Normal close and cutoff semantics

GnoSwap `CollectFee` has no historical timestamp or fee-growth cutoff argument. Teshio cannot enforce an exact wall-clock cutoff at `EarliestCloseTime`.

The fee claim remains active until the successful close transaction. Once `EarliestCloseTime` is reached, anyone may call close. The final collection includes fees returned by GnoSwap at execution, including any accrual caused by delay after the earliest close time.

Normal close must perform final collection before setting `Closed`. State mutation and the cross-realm call must be atomic. If collection panics, no close state or accounting update may persist. A closed agreement cannot collect again.

## 9. Withdrawal and principal redemption

The fee claimant may withdraw up to `Claimable0/1` at any time after those balances are credited, including after `Closed` or `Redeemed`. A successful withdrawal decrements the corresponding claimable balance exactly once. A failed transfer must abort without decrementing the balance.

Normal principal redemption requires `Closed`, the recorded principal claimant as caller, and independent confirmation that Teshio owns the exact NFT. Transfer only to the recorded claimant. Redemption must not call `CollectFee`.

The fee claimant's unwithdrawn balance is a separate liability. It must not block NFT redemption and must remain withdrawable after the NFT has been returned.

## 10. Emergency exit during withdrawal halt

GnoSwap's withdrawal halt blocks `CollectFee`, while the reviewed GNFT transfer path does not use that withdrawal-halt guard. This is source-level behavior and still requires target-chain integration testing.

Emergency exit is available only from `RecoveryPending` while `IsHaltedWithdraw()` remains true. It requires both claimants to consent to the same explicit terms:

- The NFT returns to the principal claimant.
- Both parties waive only the fee claimant's right to fees that have not yet been collected by Teshio.
- Any fees already collected and credited remain owed to the fee claimant and remain withdrawable.
- The agreement terminates and cannot resume or collect again.

Each consent must be tied to the same agreement and exact exit-terms version. One party cannot consent on behalf of the other. If either party does not consent, the NFT remains in custody until normal collection can resume. This can cause an indefinite lock; that risk must be disclosed.

## 11. Security invariants

1. One position NFT can back at most one nonterminal agreement.
2. Teshio must verify custody before recording a deposit.
3. The principal claimant is immutable.
4. The fee claimant is set once and only after successful payment.
5. Asking price, payment token, earliest close time, and position ID cannot change after creation.
6. Only actual net fees returned by GnoSwap are credited.
7. Every successful collection is accounted for exactly once.
8. No fee collection occurs after `Closed` or `Redeemed`.
9. No principal redemption occurs before normal close, except the explicitly mutual emergency exit or unpurchased cancellation.
10. Already-credited fee balances survive close, redemption, and emergency exit.
11. Fee withdrawals cannot exceed recorded claimable balances.
12. Failed cross-realm calls and failed transfers must not leave partial state.
13. Emergency exit requires two independent consents to identical terms.
14. No arbitrary caller can mark recovery pending without the public withdrawal-halt getter confirming the halt.
15. A delayed close may include additional fees after earliest close time; this is disclosed in the purchase terms.

## 12. Implementation gates

Before deployment, tests must prove:

- NFT deposit, custody verification, and one-agreement-per-position enforcement.
- Exact asking-price payment and one-time purchase.
- Fee collection credits actual net amounts.
- Halt getter correctly moves an agreement into `RecoveryPending` without calling `CollectFee`.
- Unexpected cross-realm panic leaves the prior state unchanged.
- Recovery can resume after halt clears.
- Normal close is permissionless after earliest close time and performs one final collection.
- Duplicate close and collection calls cannot double-credit.
- Fee claimant can withdraw after close and after NFT redemption.
- Principal can redeem despite outstanding fee balances.
- Emergency exit requires both matching consents and preserves already-credited balances.
- Unpurchased cancellation returns the NFT only to the principal claimant.

The current repository contract is a custody prototype. This specification does not mean the lifecycle is implemented, compiled, deployed, or tested on Onyx.
