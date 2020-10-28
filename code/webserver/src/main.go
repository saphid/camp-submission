package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/gorilla/mux"
)

// main intialises a server with four endpoints
func main() {
	r := mux.NewRouter()
	r.HandleFunc("/", homeHandler)
	r.HandleFunc("/upsert", upsertHandler)
	r.HandleFunc("/show", getItem)
	r.HandleFunc("/error", errorHandler)

	srv := &http.Server{
		Addr:         ":8080",
		Handler:      r,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}

// homeHandler is a simple endpoint that could be used a a health check
func homeHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Home")
}

// upsertHandler create or sets a single item in a dynamo db table
func upsertHandler(w http.ResponseWriter, r *http.Request) {
	client, err := newDynamodbClient()

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Println("Failed to start session")
		fmt.Println(err.Error())
		return
	}

	item := Item{
		Year:   2015,
		Title:  "The Big New Movie",
		Plot:   "Nothing happens at all.",
		Rating: 0.0,
	}

	av, err := dynamodbattribute.MarshalMap(item)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Println("Got error marshalling new movie item:")
		fmt.Println(err.Error())
		return
	}

	tableName, _ := os.LookupEnv("TABLE_NAME")

	input := &dynamodb.PutItemInput{
		Item:      av,
		TableName: aws.String(tableName),
	}

	_, err = client.PutItem(input)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Println("Got error calling PutItem:")
		fmt.Println(err.Error())
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Added!")
}

// getItem tries to get the item created in upsertItem
func getItem(w http.ResponseWriter, r *http.Request) {
	client, err := newDynamodbClient()

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Println("Failed to start session")
		fmt.Println(err.Error())
		return
	}

	tableName, _ := os.LookupEnv("TABLE_NAME")
	movieName := "The Big New Movie"
	movieYear := "2015"
	result, err := client.GetItem(&dynamodb.GetItemInput{
		TableName: aws.String(tableName),
		Key: map[string]*dynamodb.AttributeValue{
			"Year": {
				N: aws.String(movieYear),
			},
			"Title": {
				S: aws.String(movieName),
			},
		},
	})
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Println(err.Error())
		return
	}
	if result.Item == nil {
		w.WriteHeader(http.StatusNotFound)
		fmt.Printf("Could not find '%v'", movieName)
		return
	}

	item := Item{}

	err = dynamodbattribute.UnmarshalMap(result.Item, &item)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Printf("Failed to unmarshal Record, %v", err)
		return
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Found item:")
	fmt.Fprintln(w, "Year:  ", item.Year)
	fmt.Fprintln(w, "Title: ", item.Title)
	fmt.Fprintln(w, "Plot:  ", item.Plot)
	fmt.Fprintln(w, "Rating:", item.Rating)
}

// Always returns an error
func errorHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusInternalServerError)
}

// newDynamodbClient creates a client with the default aws session
func newDynamodbClient() (*dynamodb.DynamoDB, error) {
	sess, err := session.NewSession()
	if err != nil {
		return nil, err
	}
	return dynamodb.New(sess), nil
}

// Item is just a sample struct
type Item struct {
	Year   int
	Title  string
	Plot   string
	Rating float64
}
