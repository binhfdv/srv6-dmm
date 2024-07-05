package producer

import (
	"net/http"
	"strconv"

	"github.com/free5gc/openapi/models"
	"github.com/free5gc/smf/internal/context"
	"github.com/free5gc/util/httpwrapper"
)

type PDUSessionInfo struct {
	Supi         string
	PDUSessionID string
	Dnn          string
	Sst          string
	Sd           string
	AnType       models.AccessType
	PDUAddress   string
	SessionRule  models.SessionRule
	UpCnxState   models.UpCnxState
	Tunnel       context.UPTunnel
	//add code
	UPNode		string
}

func HandleOAMGetUEPDUSessionInfo(smContextRef string) *httpwrapper.Response {
	smContext := context.GetSMContextByRef(smContextRef)
	if smContext == nil {
		httpResponse := &httpwrapper.Response{
			Header: nil,
			Status: http.StatusNotFound,
			Body:   nil,
		}

		return httpResponse
	}

	//add code
	httpResponse := &httpwrapper.Response{
		Header: nil,
		Status: http.StatusOK,
		Body: PDUSessionInfo{
			Supi:         smContext.Supi,
			PDUSessionID: strconv.Itoa(int(smContext.PDUSessionID)),
			Dnn:          smContext.Dnn,
			Sst:          strconv.Itoa(int(smContext.SNssai.Sst)),
			Sd:           smContext.SNssai.Sd,
			AnType:       smContext.AnType,
			PDUAddress:   smContext.PDUAddress.String(),
			UpCnxState:   smContext.UpCnxState,
			Tunnel: context.UPTunnel{
			// 	//UpfRoot:  smContext.Tunnel.UpfRoot,
				// ULCLRoot: smContext.Tunnel.UpfRoot,
				// DataPathPool:  smContext.Tunnel.DataPathPool.,
				PathIDGenerator: smContext.Tunnel.PathIDGenerator,

				ANInformation: smContext.Tunnel.ANInformation,
			},
			UPNode: smContext.Tunnel.DataPathPool.Print(),
			
		},
	}
	return httpResponse
}
