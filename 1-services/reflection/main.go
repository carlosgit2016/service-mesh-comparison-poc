package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
)

var (
	httpCode           int
	port               string = os.Getenv("PORT")
	downstreamServices string = os.Getenv("DOWNSTREAM_SERVICES")
	mu                 sync.Mutex
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

func requestDownstreamServices() map[string]any {
	if downstreamServices == "" {
		return nil
	}
	splitedDs := strings.Split(downstreamServices, ",")

	var wg sync.WaitGroup
	wg.Add(len(splitedDs))

	responses := map[string]any{}

	for _, ds := range splitedDs {
		go func(ds string) {
			defer wg.Done()

			mu.Lock()
			svcAdr := fmt.Sprintf("http://%s:8080", ds)
			fmt.Printf("Trying to connect to %s \n", svcAdr)

			hr, err := http.Get(svcAdr)
			if err != nil {
				fmt.Printf("Failed to request to %s \n", svcAdr)
				responses[ds] = map[string]any{
					"err": err,
				}
				fmt.Print(err)
			}

			if hr.StatusCode < 200 && hr.StatusCode >= 400 {
				fmt.Printf("Failed to connect to %s \n", svcAdr)
				responses[ds] = map[string]any{
					"err": fmt.Sprintf("Failed to connect to %s - %v", svcAdr, hr.StatusCode),
				}
			}

			defer hr.Body.Close()
			body, _ := io.ReadAll(hr.Body)
			var v any
			json.Unmarshal(body, &v)
			responses[ds] = v

			mu.Unlock()

		}(ds)
	}

	wg.Wait()
	fmt.Println("Responses: ", responses)
	return responses

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

		rds := requestDownstreamServices()

		rb, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, err)
		}
		var v any
		json.Unmarshal(rb, &v)

		c.JSON(httpCode, gin.H{
			"downstreamServices": rds,
			"metadata":           parseMetadata(),
			"headers":            c.Request.Header,
			"client_ip":          c.ClientIP(),
		})
	})

	if port == "" {
		port = "8080"
	}

	r.Run(fmt.Sprintf("0.0.0.0:%s", port))

}
