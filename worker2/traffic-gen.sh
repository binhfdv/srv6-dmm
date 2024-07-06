#!/bin/bash

# Generate binary file
# sudo apt-get install shc
# shc -f traffic-gen.sh -o traffic-gen
# ./traffic-gen uesimtun0 'image kkkk'
# ./traffic-gen uesimtun0 'image cat'
# ./traffic-gen uesimtun0 'image dog'

# Function to display usage information
function usage {
    printf "\e[1;31mUsage: $0 <arg1> <arg2>\n"
    printf "\e[1;31mDescription: Require 2 arguments: \n \t + UE interface name \n \t + service info\e[0m\n\n"
}

# Check if the number of arguments is correct
if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

# Assign arguments to variables
arg1=$1
arg2=$2

printf "\e[1;32mUE interface name: \e[1;34m$arg1\n"
printf "\e[1;32mService Info: \e[1;34m$arg2\e[0m\n"

sleep 3

i=1
while true; do
    printf "Processing the request $i...\n"
    ((i++))
    printf "\--------------------------\n"
    if [[ $arg2 == *"dog"* ]]; then
        curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.50:5000/predict --interface uesimtun0
        printf "\n--------------------------\n"

    elif [[ $arg2 == *"cat"* ]]; then
        curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.40:5000/predict --interface uesimtun0
        printf "\n--------------------------\n"

    else
        curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.30:5000/predict --interface uesimtun0
        printf "\n--------------------------\n"
        # send traffic to cat or dog
        # curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.40:5000/predict --interface uesimtun0
        # printf "\n--------------------------\n"
        curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.50:5000/predict --interface uesimtun0
        printf "\n--------------------------\n"
    fi
done

# while sleep 1; do curl -X POST -F "images=@/root/service-results/imga.jpg" 10.96.10.50:5000/predict --interface uesimtun0; done