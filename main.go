package main

import (
	"fmt"
	"log"
	"net/http"
)

type Server struct{}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Request received...")
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"message": "hello world"}`))
	fmt.Println("Response sent...")
}

func main() {
	fmt.Println("Service Starting...")
	s := &Server{}
	http.Handle("/", s)
	fmt.Println("Service Listening...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
