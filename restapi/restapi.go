package restapi

import (
	"encoding/base64"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"

	"github.com/gin-gonic/gin"
)

const (
	certificatesFolder = "/root/tests_step/certificates/"
	keysFolder         = "/root/tests_step/keys/"
	csrFolder          = "/root/tests_step/csr/"
	scriptCreateCert   = "/root/scripts/create_certificate.sh"
	scriptSignCSR      = "/root/scripts/sign_csr.sh"
)

func runScript(script string, args ...string) (string, error) {
	cmd := exec.Command(script, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Error running script %s: %v", script, err)
		return "", fmt.Errorf("script error: %s", string(output))
	}
	return string(output), nil
}

func createCertificateAndPrivateKey(c *gin.Context) {
	name := c.Query("name")
	if name == "" {
		log.Println("Error: Missing 'name' parameter")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'name' parameter"})
		return
	}

	log.Printf("Generating certificate for: %s", name)
	output, err := runScript(scriptCreateCert, name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	certPath := certificatesFolder + name + ".crt"
	keyPath := keysFolder + name + ".key"

	certBase64, _ := readFileAndEncodeBase64(certPath)
	keyBase64, _ := readFileAndEncodeBase64(keyPath)

	c.JSON(http.StatusOK, gin.H{
		"message":       "Certificate created",
		"name":          name,
		"certificate":   certBase64,
		"private_key":   keyBase64,
		"script_output": output,
	})
}

func processCSR(c *gin.Context) {
	name := c.Query("name")
	if name == "" {
		log.Println("Error: Missing 'name' parameter")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'name' parameter"})
		return
	}

	csr, err := io.ReadAll(c.Request.Body)
	if err != nil {
		log.Printf("Error reading CSR: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to read CSR"})
		return
	}

	csrPath := csrFolder + name + ".csr"
	if err := os.WriteFile(csrPath, csr, 0644); err != nil {
		log.Printf("Error saving CSR: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save CSR"})
		return
	}

	log.Printf("Signing CSR for: %s", name)
	output, err := runScript(scriptSignCSR, name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	certPath := certificatesFolder + name + ".crt"
	certBase64, _ := readFileAndEncodeBase64(certPath)

	c.JSON(http.StatusOK, gin.H{
		"message":       "CSR processed and signed certificate generated",
		"name":          name,
		"certificate":   certBase64,
		"script_output": output,
	})
}

func readFileAndEncodeBase64(path string) (string, error) {
	contentBytes, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(contentBytes), nil
}

func AddHandlers(router *gin.Engine) {
	router.POST("/certificate", createCertificateAndPrivateKey)
	router.POST("/csr", processCSR)
}
