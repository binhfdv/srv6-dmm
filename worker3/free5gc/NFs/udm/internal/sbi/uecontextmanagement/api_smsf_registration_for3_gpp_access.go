/*
 * Nudm_UECM
 *
 * Nudm Context Management Service
 *
 * API version: 1.0.1
 * Generated by: OpenAPI Generator (https://openapi-generator.tech)
 */

package uecontextmanagement

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// UpdateSMSFReg3GPP - register as SMSF for 3GPP access
func HTTPUpdateSMSFReg3GPP(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{})
}