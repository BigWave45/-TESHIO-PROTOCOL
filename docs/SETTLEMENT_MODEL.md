# Teshio Settlement and Recovery Model

**Status:** Design constraint for prototype v0.3  
**Applies to:** GnoSwap LP fee-right agreements

## 1. Why the cutoff is execution-based

GnoSwap's `CollectFee(cur, positionID)` accepts no timestamp, block-height cutoff, or historical fee-growth snapshot. It collects the fees owed when the call executes and returns the net amounts paid to the caller.

Teshio therefore cannot promise an exact wall-clock cutoff at the agreement's earliest close time. The fee right remains active until a successful close transaction. Fees accrued between earliest close time and close execution are included in the final collection.

## 2. State machine

The agreement uses five lifecycle states:

- `Deposited`: NFT held by Teshio; no buyer yet.
- `Active`: purchase completed; fee right is live.
- `RecoveryPending`: GnoSwap withdrawal halt is confirmed; Teshio retains the NFT and pauses collection.
- `Closed`: final collection succeeded and actual net fees are accounted for.
- `Redeemed`: NFT returned; agreement is terminal.

The reason for redemption must be stored separately: normal redemption after close, cancellation before purchase, or mutual emergency exit.

## 3. Cross-realm panic constraint and recovery detection

An unrecovered panic crossing a realm boundary aborts the transaction. Teshio cannot call GnoSwap, catch the panic, and then persist `RecoveryPending` in the same transaction.

The reviewed GnoSwap source exposes `halt.IsHaltedWithdraw() bool` from `gno.land/r/gnoswap/halt/v1`. Teshio must check this getter before calling `CollectFee`:

- If true, set `RecoveryPending` and return without calling `CollectFee`.
- If false, attempt collection.
- If collection unexpectedly panics, let the transaction abort. The agreement remains in its prior state.

This prevents an arbitrary caller from falsely forcing recovery pending. The getter's package path and behavior are source-verified, but availability and successful calls from Teshio on the target chain remain integration gates.

## 4. Collection while active

Anyone may call fee collection while the agreement is `Active`:

1. Require `Active`.
2. Read `IsHaltedWithdraw()`.
3. If halted, set `RecoveryPending` and return without an external collection call.
4. Otherwise call GnoSwap `CollectFee`.
5. Credit the actual net token0 and token1 amounts returned.
6. Increase cumulative collected amounts and collection count.

Do not use `GetUnclaimedFee` as a settlement amount. It is a current estimate and does not represent the actual net amount after GnoSwap's withdrawal fee.

## 5. Resume and close

If the agreement is `RecoveryPending` and the withdrawal halt clears:

- Before earliest close time, anyone may resume normal collection. A successful collection returns the agreement to `Active`.
- At or after earliest close time, anyone may execute normal close. Teshio performs final collection, credits actual net amounts, and changes state to `Closed`.
- If the halt is still active, Teshio remains in `RecoveryPending` and does not attempt collection.

Normal close is permissionless after earliest close time. It is not automatic. The final close transaction includes any fees accrued until execution.

## 6. Emergency exit

If the withdrawal halt persists, the NFT may otherwise remain locked indefinitely. The only v0.3 emergency exit is mutual consent.

Both the principal claimant and fee claimant must separately authorize the same agreement-specific exit terms. Those terms must state:

- Return the NFT to the principal claimant.
- Waive the fee claimant's rights only to fees not yet collected by Teshio.
- Preserve all already-collected and credited fee balances as withdrawable liabilities.
- Terminate the agreement permanently and prohibit further fee collection.

The exit can execute only while the agreement is `RecoveryPending` and the withdrawal halt remains true. Consent must be bound to the same terms version. No party or administrator can unilaterally force the exit.

If the fee claimant refuses, the NFT remains in custody until collection can resume. This indefinite-lock risk is intentional and must be disclosed; the protocol has no verified primitive that can collect fees while GnoSwap withdrawals are halted.

## 7. Fee withdrawal and NFT redemption

Fee balances are liabilities independent of the NFT.

- The fee claimant may withdraw already-credited balances after `Closed` or `Redeemed`.
- A successful withdrawal decrements the balance exactly once.
- A failed token transfer must abort without decrementing the balance.
- Normal principal redemption is permitted after `Closed`, only to the recorded principal claimant.
- Redemption verifies that Teshio still owns the NFT and transfers it without calling `CollectFee`.
- Outstanding fee balances must never block principal redemption.

## 8. Atomicity requirements

Gno transaction documentation states that an unrecovered panic aborts execution and does not save changes. The interrealm specification describes an unrecovered panic crossing a realm boundary as a transaction-aborting panic.

Implementation rules:

1. Validate state, caller, timing, token keys, and halt status before external mutation.
2. Do not recover from a downstream GnoSwap panic and continue.
3. If a downstream API returns an error after earlier state changes, panic rather than return normally.
4. Credit fee balances only from successful `CollectFee` return values.
5. Mark `Closed` only after final collection succeeds.
6. Decrement fee balances only as part of a successful token transfer.
7. Verify NFT ownership before and after custody-changing transfers.

These are documented transaction semantics, not proof that the full Teshio-to-GnoSwap call sequence has been exercised on Onyx. The exact target-chain integration still needs testing.

## 9. Required tests

1. Halt true causes transition to `RecoveryPending` without invoking `CollectFee`.
2. An arbitrary caller cannot force `RecoveryPending` when the public halt getter is false.
3. Unexpected `CollectFee` panic leaves agreement state and balances unchanged.
4. Halt clears and agreement resumes before earliest close time.
5. Halt clears and permissionless close succeeds after earliest close time.
6. Final close credits exactly the net values returned by GnoSwap.
7. No collection is possible after `Closed` or `Redeemed`.
8. Duplicate close cannot credit twice.
9. Fee claimant can withdraw after close and after NFT redemption.
10. Principal can redeem while fee claimant has an unwithdrawn balance.
11. Emergency exit fails with only one consent or mismatched terms.
12. Emergency exit preserves already-credited fee balances and waives only uncollected fees.
13. Emergency exit cannot execute after the halt clears.
14. Unpurchased cancellation returns the NFT only to the principal claimant.

## 10. Source references

- GnoSwap halt getter: https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/halt/v1/getters.gno
- GnoSwap position proxy: https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/proxy.gno
- GnoSwap position implementation: https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/v1/position.gno
- Gno interrealm v2 semantics: https://docs.gno.land/resources/gno-interrealm-v2/
- Effective Gno guidance: https://docs.gno.land/resources/effective-gno/

