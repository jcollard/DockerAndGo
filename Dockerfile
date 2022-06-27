# FROM golang:alpine
FROM golang:1.18-alpine

RUN mkdir /go/src/app 

COPY main.go /go/src/app/
COPY go.mod /go/src/app/
WORKDIR /go/src/app
RUN go build .

ENTRYPOINT [ "./app" ]
