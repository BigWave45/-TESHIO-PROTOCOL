# Teshio Settlement Model

**Status:** Design constraint for prototype v0.2  
**Applies to:** GnoSwap LP fee claims

## 1. The fixed-time cutoff problem

GnoSwap's public `CollectFee(cur, positionID)` method accepts no timestamp, block-height cutoff, or fee-growth snapshot. It collects the fees currently owed to the position and sends the net amounts to the caller. The public getter `GetUnclaimedFee(positionID)` reports the current unclaimed amount; it does not expose a historical amount as of an earlier timestamp.

Consequently, Teshio cannot safely promise that a claim receives exactly the fees generated before a wall-clock maturity timestamp if collection occurs later. A collection transaction after the timestamp can include fees accrued between the timestamp and execution. The existing integration does not provide a way to split those amounts.

The earlier specification's statement that fees stop being attributed automatically at the maturity timestamp was inaccurate. Do not implement that assumption.

## 2. Prototype rule: earliest close time, permissionless close

For v0.2, replace hard maturity with an **earliest close time**:

- The seller creates the agreement with a minimum active period.
- The fee claim remains active until a successful `CloseAgreement` transaction.
- `CloseAgreement` becomes callable by anyone once the earliest close time is reached.
- The close transaction calls GnoSwap `CollectFee` while Teshio still owns the NFT.
- All fees returned by that call are credited to the fee claimant.
- The agreement then enters a closed state. No later fee collection is permitted for that agreement.
- The principal claimant can redeem the NFT only after the final fee balance has been accounted for and the close state is final.

This is deliberately not a precise time-based cutoff. The fee buyer receives fees accrued through the successful close transaction, including any additional accrual caused by a delay between earliest close time and execution. The interface and agreement terms must disclose this.

Permissionless closing removes dependence on the seller's cooperation. It does not make closure automatic; a transaction must still be submitted. A keeper bounty can be considered only after the core accounting works.

## 3. Fee collection before close

During the active period, anyone may call `CollectAgreementFees`:

1. Require the agreement to be active.
2. Call GnoSwap `CollectFee` from the Teshio realm.
3. Record the actual net token0 and token1 amounts returned.
4. Increase the fee claimant's claimable balances by exactly those amounts.
5. Emit an event or persist a collection record for auditability.

A repeated call with no new fees must credit zero. The accounting must use returned amounts, not a UI estimate or a pre-call balance difference.

## 4. Close and redemption invariants

- Only an active agreement can be closed.
- Closing is permissionless after the earliest close time.
- The close operation collects once more before changing state.
- State changes and the GnoSwap call must be atomic under Gno transaction semantics; if any step panics, no partial state may persist.
- Once closed, no fee collection or fee-claim transfer is allowed.
- Fee claims remain withdrawable after close.
- Principal redemption is allowed only after close and after the NFT is still verified as held by Teshio.
- The NFT is transferred only to the recorded principal claimant.
- Fee balances and the NFT redemption are independent: a fee claimant's unclaimed balance must not trap the principal forever. The protocol must reserve the fee balance and allow the principal NFT redemption once the final collection is accounted for.

## 5. Scope exclusions

Do not add any of the following until the first lifecycle is proven:

- transferable principal/yield tokens;
- a secondary market or AMM;
- partial fee-right sales;
- multiple NFTs per agreement;
- a fixed APR or promised return;
- oracle dependencies;
- staked positions;
- principal withdrawal before close.

## 6. Required tests

1. Close is rejected before earliest close time.
2. Any account can close after earliest close time.
3. The close transaction collects outstanding fees before marking the agreement closed.
4. The amounts credited equal the amounts returned by GnoSwap, net of its withdrawal fee.
5. No fee can be collected after close.
6. Repeated close calls cannot collect or credit twice.
7. The principal claimant cannot redeem before close.
8. The principal claimant can redeem after close even if the fee claimant has not withdrawn already-credited fees.
9. A failed GnoSwap call leaves the agreement active and accounting unchanged.
10. A zero-fee collection creates no claimable balance.

## 7. Source facts used

- GnoSwap position proxy exposes `CollectFee(cur, positionId)` with no timestamp parameter.
- The implementation checks that the caller owns the unstaked NFT or is its configured operator.
- It returns net token amounts paid to the caller and raw amounts before the withdrawal fee.
- The getter exposes `GetUnclaimedFee(positionId)`, which is a current-state read.

Sources:
- https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/proxy.gno
- https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/getter.gno
- https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/v1/position.gno
