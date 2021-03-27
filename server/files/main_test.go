package main

import (
	"testing"
)

func test(t *testing.T) {
	addition := functionToTest(2, 2)

	if addition != 4 {
		t.Fatalf("function to test error")
	}
}
