package protocol

import (
	"gno.land/p/nt/grc721/v0"
	"gno.land/p/nt/ufmt/v0"
	"gno.land/r/gnoswap/gnft"
	"gno.land/r/gnoswap/position"
)

type Escrow struct {
	PositionID uint64
	Depositor  address
	Deposited  bool
}

var (
	selfAddress address
	escrows     = make(map[uint64]Escrow)
)

func init(cur realm) {
	selfAddress = cur.Address()
}

// DepositPosition escrows an unstaked GnoSwap position NFT.
// The depositor must own the position and approve this realm before calling.
func DepositPosition(cur realm, positionID uint64) {
	if !cur.IsCurrent() {
		panic("teshio: invalid realm context")
	}

	caller := cur.Previous().Address()

	if _, exists := escrows[positionID]; exists {
		panic("teshio: position already escrowed")
	}

	owner, err := gnft.OwnerOf(positionIDToken(positionID))
	if err != nil {
		panic("teshio: position NFT does not exist")
	}
	if owner != caller {
		panic("teshio: caller is not the position owner")
	}

	liquidity, err := position.GetPositionLiquidity(positionID)
	if err != nil {
		panic("teshio: position record not found")
	}
	if liquidity == "0" {
		panic("teshio: position has no liquidity")
	}

	burned, err := position.IsBurned(positionID)
	if err != nil || burned {
		panic("teshio: burned position is not eligible")
	}

	// GNFT checks that this realm is approved to transfer the specific NFT.
	if err := gnft.TransferFrom(cross(cur), caller, selfAddress, positionIDToken(positionID)); err != nil {
		panic("teshio: NFT transfer failed")
	}

	// Do not record escrow until custody is independently confirmed.
	ownerAfter, err := gnft.OwnerOf(positionIDToken(positionID))
	if err != nil || ownerAfter != selfAddress {
		panic("teshio: custody verification failed")
	}

	escrows[positionID] = Escrow{
		PositionID: positionID,
		Depositor:  caller,
		Deposited:  true,
	}
}

// GetEscrow returns the recorded depositor and current custody status.
func GetEscrow(positionID uint64) (address, bool) {
	escrow, exists := escrows[positionID]
	if !exists || !escrow.Deposited {
		return address(""), false
	}

	owner, err := gnft.OwnerOf(positionIDToken(positionID))
	if err != nil {
		return escrow.Depositor, false
	}

	return escrow.Depositor, owner == selfAddress
}

// IsPositionEscrowed reports whether a position ID has an active escrow record.
func IsPositionEscrowed(positionID uint64) bool {
	escrow, exists := escrows[positionID]
	if !exists {
		return false
	}
	return escrow.Deposited
}

func positionIDToken(positionID uint64) grc721.TokenID {
	return grc721.TokenID(ufmt.Sprintf("%d", positionID))
}
