package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
)

var (
	httpCode int
	port     string = os.Getenv("PORT")
)

func parseMetadata() map[string]any {
	return map[string]any{
		"pod_name":        os.Getenv("METADATA_NAME"),
		"namespace":       os.Getenv("METADATA_NAMESPACE"),
		"node":            os.Getenv("NODE_NAME"),
		"service_account": os.Getenv("SERVICE_ACCOUNT"),
		"hostIP":          os.Getenv("HOST_IP"),
		"podIP":           os.Getenv("POD_IP"),
	}
}

func main() {

	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		envHttpCode := os.Getenv("HTTP_CODE")

		if envHttpCode == "" {
			httpCode = 200
		} else {
			n, err := strconv.Atoi(envHttpCode)
			if err != nil {
				c.JSON(http.StatusInternalServerError, err)
			}

			httpCode = n
		}

		c.JSON(httpCode, parseMetadata())
	})

	if port == "" {
		port = "8080"
	}

	r.Run(fmt.Sprintf("0.0.0.0:%s", port))

}
