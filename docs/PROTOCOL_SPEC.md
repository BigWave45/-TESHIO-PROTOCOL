# Teshio Protocol: Initial Specification

**Status:** Draft  
**Target:** Gno testnet  
**Version:** 0.1.0

## 1. Problem

A GnoSwap liquidity position combines two economic exposures:

1. the underlying liquidity position, including its changing token composition and market value;
2. the right to collect swap fees generated while the position is active.

A liquidity provider may want to retain the underlying position while selling the right to future fees. A separate buyer may want fee exposure without taking custody of the underlying position.

Teshio explores whether these rights can be separated through an on-chain agreement.

## 2. Proposed agreement

An agreement is created when a provider deposits an eligible GnoSwap position NFT into Teshio.

The agreement records:

- agreement ID;
- GnoSwap position ID;
- depositor / principal claimant;
- fee claimant;
- supported token paths;
- creation time and maturity time;
- upfront consideration and payment status;
- collected fee amounts by token;
- fee distribution status;
- principal redemption status;
- lifecycle status.

The vault owns the deposited NFT for the agreement's full active term.

## 3. Rights

### Principal claim

The principal claimant is entitled to receive the original GnoSwap position NFT after maturity, provided that the agreement has been settled and no fee distribution remains outstanding.

The principal claim does not guarantee a fixed monetary value. The underlying position remains exposed to price movement, impermanent loss, range inactivity, protocol changes, and other risks inherent to concentrated liquidity.

### Fee claim

The fee claimant is entitled to the eligible swap fees actually collected by the vault during the agreement term, net of any GnoSwap withdrawal fee and any explicitly disclosed protocol fee.

The fee claimant is not entitled to a guaranteed amount. If the position earns no fees, the fee claim may be worth zero.

## 4. Initial lifecycle

1. **Create:** provider specifies an eligible position, maturity, fee-claim price, and supported terms.
2. **Deposit:** provider transfers the unstaked position NFT to the Teshio vault.
3. **Verify:** Teshio verifies that the vault owns the NFT and records the agreement.
4. **Purchase:** buyer pays the agreed consideration and becomes the fee claimant.
5. **Accrue:** swap fees accumulate within the GnoSwap position.
6. **Collect:** the vault calls GnoSwap's fee-collection method as the NFT owner.
7. **Account:** Teshio records actual token amounts received and makes them claimable by the fee claimant.
8. **Mature:** after the maturity timestamp, no new fees are attributed to the agreement.
9. **Settle:** any outstanding eligible fees are collected and made claimable.
10. **Redeem:** the principal claimant retrieves the NFT after fee accounting is complete.

The implementation must define exact cutoff semantics. A transaction's block time and execution order must not permit both parties to claim the same fee period.

## 5. GnoSwap integration facts to validate

The current GnoSwap position implementation exposes CollectFee, which checks that the caller is the position owner or configured operator. The method sends collected swap fees to that caller. This suggests that a Teshio vault holding the NFT can collect fees into its own realm address, then distribute the received tokens under Teshio's own accounting.

GnoSwap's scenario test also demonstrates transferring a position NFT and collecting fees under the new owner's address.

Relevant source references:

- [GnoSwap position implementation](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/v1/position.gno)
- [GnoSwap NFT transfer and fee-collection scenario](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/scenario/position/position_transfer_with_collect_fee_filetest.gno)

These source-level facts do not yet prove that the proposed Teshio realm integration compiles or behaves correctly on the target testnet. That must be tested directly.

## 6. Non-goals for the first prototype

- Fixed or guaranteed yield.
- Lending or borrowing against fee claims.
- Leverage or liquidation.
- Automated market making for fee claims.
- Oracle-based pricing.
- Cross-chain assets.
- Staked GnoSwap positions.
- Multiple positions bundled into one agreement.

## 7. Security invariants

The implementation must preserve all of the following:

1. A position NFT can back at most one active agreement.
2. The vault cannot transfer or redeem the NFT while the fee claim is active.
3. The principal claimant cannot redeem before maturity and completed settlement.
4. The fee claimant cannot withdraw more tokens than the vault actually received and credited.
5. Every collected token amount is accounted for exactly once.
6. Repeated collection or claim calls cannot duplicate credit or payment.
7. Failed token transfers must not leave accounting marked as paid.
8. Agreement terms cannot be changed after the fee claim is purchased, except for explicitly defined administrative emergency actions.
9. Only supported, verified GnoSwap position contracts and token paths may be used.
10. A paused agreement must have a documented recovery path that does not silently confiscate either claim.

## 8. Open questions before implementation

- Exact GnoSwap realm paths and callable signatures on the current Onyx testnet deployment.
- Whether the GnoSwap NFT transfer flow can transfer directly from a user to the Teshio realm using the deployed GRC-721 interface.
- How the vault safely invokes CollectFee through inter-realm calls.
- How Teshio verifies the NFT owner and position metadata on-chain.
- Whether collected GRC-20 tokens can be held and transferred by the Teshio realm using the deployed token interfaces.
- Whether fee collection can be permissionlessly triggered, and how keeper incentives are handled.
- Exact maturity cutoff and treatment of fees accrued before maturity but collected afterward.
- Recovery behavior if GnoSwap is halted, upgraded, or its position interface changes.

## 9. Prototype acceptance criteria

The first end-to-end test is successful only when:

1. a test user deposits an eligible unstaked GnoSwap position NFT into Teshio;
2. Teshio proves on-chain custody of that exact NFT;
3. a second test user purchases the fee claim using a test token;
4. a swap generates fees for the position;
5. Teshio collects those fees as the NFT owner;
6. the fee claimant withdraws exactly the amount credited;
7. the principal claimant cannot withdraw the NFT before maturity;
8. after maturity and settlement, the principal claimant can retrieve the NFT;
9. replayed calls and duplicate claims fail without changing balances.

No user interface should be built before these contract-level acceptance criteria are met.
