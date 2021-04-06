package main

import (
	"io"
	"log"
	"net/http"
)

func functionToTest(a int32, b int32) int32 {
	return a + b
}

func main() {
	// Hello world, the web server

	helloHandler := func(w http.ResponseWriter, req *http.Request) {
		io.WriteString(w, "Hello, world!\n")
	}

	http.HandleFunc("/hello", helloHandler)
	log.Println("Listing for requests at http://localhost:8081/hello")
	log.Fatal(http.ListenAndServe(":8081", nil))
}
