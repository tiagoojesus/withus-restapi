package main

import (
	"example.com/api/restapi"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	restapi.AddHandlers(r)
	r.Run()
}
