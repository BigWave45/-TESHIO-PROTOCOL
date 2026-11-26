# Teshio Protocol: Initial Specification

**Status:** Draft  
**Target:** Gno testnet  
**Version:** 0.2.0

## 1. Problem

A GnoSwap liquidity position combines two economic exposures:

1. the underlying liquidity position, including its changing token composition and market value;
2. the right to collect swap fees generated while the position is active.

A liquidity provider may want to retain the underlying position while selling the right to future fees. A separate buyer may want fee exposure without taking custody of the underlying position.

Teshio explores whether these rights can be separated through an on-chain agreement.

## 2. Proposed agreement

An agreement is created when a provider deposits an eligible, unstaked GnoSwap position NFT into Teshio.

The agreement records:

- agreement ID and GnoSwap position ID;
- principal claimant and fee claimant;
- creation time and earliest close time;
- agreed purchase consideration and payment status;
- token0 and token1 fee balances collected by Teshio;
- fee-claim withdrawal balances;
- close and principal-redemption status.

Teshio owns the NFT while the agreement is active and closed-but-not-redeemed.

## 3. Rights

### Principal claim

The principal claimant is entitled to receive the original GnoSwap position NFT after the agreement is closed and final fee collection is accounted for.

This is a claim to the same LP position NFT, not a guarantee of its monetary value. The position remains exposed to price movement, impermanent loss, range inactivity, protocol changes, and other concentrated-liquidity risks.

### Fee claim

The fee claimant is entitled to the actual net swap fees collected by Teshio while the agreement is active, including the final collection made during close.

The fee claim is not a fixed or guaranteed return. If the position earns no fees, the claim may be worth zero.

## 4. Lifecycle

1. **Create:** provider specifies a position, earliest close time and asking price.
2. **Approve and deposit:** provider approves the Teshio realm to transfer the specific NFT, then deposits it.
3. **Verify:** Teshio verifies the NFT exists, is eligible and is held by the Teshio realm.
4. **Purchase:** buyer pays the agreed consideration and becomes the fee claimant.
5. **Collect:** while active, anyone may trigger fee collection. Teshio credits the actual net amounts returned by GnoSwap.
6. **Close:** once earliest close time is reached, anyone may call close. Teshio performs one final fee collection and marks the agreement closed.
7. **Claim fees:** the fee claimant may withdraw its recorded token0 and token1 balances.
8. **Redeem principal:** the original principal claimant may retrieve the NFT after close and final accounting.

## 5. Important cutoff limitation

GnoSwap's `CollectFee` interface has no timestamp or historical fee-growth cutoff parameter. It collects all fees currently owed when the call executes. Therefore, Teshio cannot guarantee an exact wall-clock cutoff at earliest close time.

For v0.2, earliest close time is the first time at which the agreement may be closed, not an automatic expiry. The fee claim remains active until the successful close transaction. Fees accrued between earliest close time and execution are included in the final collection. This delay risk must be disclosed to buyers.

See [Settlement Model](SETTLEMENT_MODEL.md).

## 6. Non-goals

- Fixed or guaranteed yield.
- Lending, borrowing, leverage or liquidation.
- Automated market making for fee claims.
- Oracle-based pricing.
- Cross-chain assets.
- Staked GnoSwap positions.
- Multiple positions bundled into one agreement.
- Secondary trading of claims in the first prototype.

## 7. Security invariants

1. A position NFT backs at most one active agreement.
2. The NFT remains in Teshio custody until close and principal redemption.
3. The principal claimant cannot redeem before close.
4. The fee claimant cannot withdraw more than Teshio actually collected and credited.
5. Every collected amount is accounted for exactly once.
6. Repeated collection and close calls cannot duplicate credit or payment.
7. Failed token transfers must not leave accounting marked as paid.
8. Purchased agreement terms cannot be changed.
9. Only the verified GnoSwap position contract and supported token contracts are accepted.
10. The principal claimant can redeem after close even if the fee claimant has not withdrawn already-credited fees.

## 8. Open integration questions

- Confirm exact package paths and deployed APIs on Onyx.
- Prove the approval and NFT transfer sequence in a testnet transaction.
- Prove Teshio can call `CollectFee` through an inter-realm call and receive both fee tokens.
- Confirm the exact GRC-20 transfer interfaces and token balance accounting.
- Confirm transaction atomicity when a downstream inter-realm call panics.
- Confirm how Gno timestamps are exposed and compared in the current toolchain.
- Define emergency recovery if GnoSwap is halted or its interfaces change.

## 9. Contract acceptance criteria

1. A user deposits an eligible unstaked position NFT.
2. Teshio proves custody of that exact NFT.
3. A second user purchases the fee claim.
4. A swap generates fees for the position.
5. Teshio collects fees as NFT owner and credits actual returned amounts.
6. The fee claimant withdraws exactly the credited amounts.
7. Close is rejected before earliest close time.
8. Any account can close after earliest close time.
9. Close performs final collection and permanently ends fee accrual under the agreement.
10. Principal redemption fails before close and succeeds after close.
11. Replayed calls and duplicate claims cannot alter balances.

No user interface should be built before these contract-level acceptance criteria are met.
