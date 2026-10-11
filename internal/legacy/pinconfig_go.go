//go:build !baremetal

package legacy

import "tinygo.org/x/drivers/internal/pin"

// This file compiles for "big" Go and for TinyGo targets without
// hardware pins, such as wasm.

func configurePinOut(p pin.Output)          {}
func configurePinInput(p pin.Input)         {}
func configurePinInputPulldown(p pin.Input) {}
func configurePinInputPullup(p pin.Input)   {}
func pinIsNoPin(a any) bool                 { return false }
