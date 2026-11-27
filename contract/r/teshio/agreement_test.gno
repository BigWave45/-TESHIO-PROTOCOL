package teshio

import "testing"

func TestAgreementTransitions(t *testing.T) {
	if !isValidAgreementTransition(AgreementDeposited, AgreementActive) {
		t.Error("deposited -> active should be allowed")
	}
	if !isValidAgreementTransition(AgreementDeposited, AgreementRedeemed) {
		t.Error("deposited -> redeemed should be allowed")
	}
	if !isValidAgreementTransition(AgreementActive, AgreementActive) {
		t.Error("active -> active should be allowed")
	}
	if !isValidAgreementTransition(AgreementActive, AgreementRecoveryPending) {
		t.Error("active -> recovery pending should be allowed")
	}
	if !isValidAgreementTransition(AgreementActive, AgreementClosed) {
		t.Error("active -> closed should be allowed")
	}
	if !isValidAgreementTransition(AgreementRecoveryPending, AgreementActive) {
		t.Error("recovery pending -> active should be allowed")
	}
	if !isValidAgreementTransition(AgreementRecoveryPending, AgreementClosed) {
		t.Error("recovery pending -> closed should be allowed")
	}
	if !isValidAgreementTransition(AgreementRecoveryPending, AgreementRedeemed) {
		t.Error("recovery pending -> redeemed should be allowed")
	}
	if !isValidAgreementTransition(AgreementClosed, AgreementRedeemed) {
		t.Error("closed -> redeemed should be allowed")
	}

	if isValidAgreementTransition(AgreementDeposited, AgreementClosed) {
		t.Error("deposited -> closed must be rejected")
	}
	if isValidAgreementTransition(AgreementActive, AgreementRedeemed) {
		t.Error("active -> redeemed must be rejected")
	}
	if isValidAgreementTransition(AgreementClosed, AgreementActive) {
		t.Error("closed -> active must be rejected")
	}
	if isValidAgreementTransition(AgreementRedeemed, AgreementActive) {
		t.Error("redeemed -> active must be rejected")
	}
	if isValidAgreementTransition(AgreementRedeemed, AgreementRedeemed) {
		t.Error("redeemed must be terminal")
	}
}
