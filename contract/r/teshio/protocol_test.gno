package teshio

import "testing"

func TestEmptyEscrow(t *testing.T) {
    if IsPositionEscrowed(1) {
        t.Errorf("position 1 should not be escrowed")
    }

    _, exists := GetEscrow(1)
    if exists {
        t.Errorf("position 1 should not have an escrow record")
    }
}
