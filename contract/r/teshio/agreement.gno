package teshio

// AgreementState represents the lifecycle of a fee-right agreement.
type AgreementState uint8

const (
	AgreementDeposited AgreementState = iota + 1
	AgreementActive
	AgreementRecoveryPending
	AgreementClosed
	AgreementRedeemed
)

// AgreementExitReason records how an agreement ended.
type AgreementExitReason uint8

const (
	ExitNone AgreementExitReason = iota
	ExitCancellation
	ExitNormalRedemption
	ExitMutualEmergency
)

// Agreement records the terms, parties and accounting state
// associated with one escrowed GnoSwap position.
type Agreement struct {
	AgreementID      uint64
	PositionID       uint64

	PrincipalClaimant address
	FeeClaimant       address

	PaymentTokenKey string
	AskingPrice     int64

	EarliestCloseTime int64
	CreatedAt         int64
	PurchasedAt       int64
	ClosedAt          int64
	RedeemedAt        int64

	State     AgreementState
	ExitReason AgreementExitReason

	Token0Key string
	Token1Key string

	Claimable0 int64
	Claimable1 int64

	TotalCollected0 int64
	TotalCollected1 int64

	CollectionCount uint64

	EmergencyPrincipalConsent bool
	EmergencyFeeConsent       bool
	EmergencyConsentVersion   uint64
}

// Agreement storage.
var (
	agreements       = make(map[uint64]Agreement)
	nextAgreementID uint64 = 1
)

// isValidAgreementTransition determines whether a lifecycle transition
// is permitted by the protocol.
func isValidAgreementTransition(from, to AgreementState) bool {
	switch from {
	case AgreementDeposited:
		return to == AgreementActive ||
			to == AgreementRedeemed

	case AgreementActive:
		return to == AgreementActive ||
			to == AgreementRecoveryPending ||
			to == AgreementClosed

	case AgreementRecoveryPending:
		return to == AgreementActive ||
			to == AgreementClosed ||
			to == AgreementRedeemed

	case AgreementClosed:
		return to == AgreementRedeemed

	default:
		return false
	}
}
