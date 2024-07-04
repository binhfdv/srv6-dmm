#!/bin/bash

function usage {
    echo "Usage: $0 <arg1>"
    echo "Description: Require one argument of the destination"
}

# Check if the number of arguments is correct
if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

arg1=$1

printf "\e[1;32mMonitoring...\e[0m\n"
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:4:5:8:fd44::

# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.1.3 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.1.3 24 fcbb:bb00:01:: fcbb:bb00:6:5:9:fd44::
# if [[ $arg1 == *"3"* ]]; then
#     echo "3"

flag=""
while true; do
    # Define the Prometheus query
    QUERY='sum(rate(container_cpu_usage_seconds_total{container_label_io_kubernetes_pod_name=~"^deploy-.*"}[1m])) by (container_label_io_kubernetes_pod_name, instance) * 100'

    # Prometheus endpoint URL
    PROMETHEUS_URL="http://192.168.20.1:9090/api/v1/query?query="

    # Encode the query for use in a URL
    ENCODED_QUERY=$(echo -n "$QUERY" | jq -s -R -r @uri)

    # Make the HTTP request to the Prometheus API
    response=$(curl -s "$PROMETHEUS_URL$ENCODED_QUERY" | jq .)
    
    while IFS= read -r line; do
        container_label=$(echo "$line" | jq -r '.metric.container_label_io_kubernetes_pod_name')
        instance=$(echo "$line" | jq -r '.metric.instance')
        value=$(echo "$line" | jq -r '.value[1]')
        
        # Debugging output
        # echo "container_label: $container_label, instance: $instance, value: $value"
        
        if [[ $(echo "$value > 50" | bc) -eq 1 ]] && [[ "$instance" == *"20.10:8082"* ]]; then
            flag="20.10"
        elif [[ $(echo "$value > 50" | bc) -eq 1 ]] && [[ "$instance" == *"20.8:8082"* ]]; then
            flag="20.8"
        fi
    done < <(echo "$response" | jq -c '.data.result[]')

    if [[ "$flag" == "20.10" ]]; then
        echo "$flag"
        bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::
        flag=""
        sleep 10
    elif [[ "$flag" == "20.8" ]]; then
        echo "$flag"
        bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
        flag=""
        sleep 10
    else
        echo "System is good"
    fi
done

    # bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::
    # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:9:8:fd44::
    # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
    # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:5:8:fd44::

# elif [[ $arg1 == *"1"* ]]; then
#     echo "1"
#     # bash util/onos-cmd route-gtp4d-insert device:r1 192.168.1.3 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
#     # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:4:5:8:9:fd44::
#     # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
#     # bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:7:9:fd44::

# else
#     echo "Invalid argument. Please specify either worker '1' or '3'."
# fi
