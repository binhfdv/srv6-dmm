i=1
while true; do
    printf "Processing the request $i...\n"
    ((i++))
    curl -X POST -F "images=@/root/service_app/Persian_5.jpg" 10.96.10.30:5000/predict
    printf "\n--------------------------\n"
    # send traffic to cat or dog
    curl -X POST -F "images=@/root/service_app/Persian_5.jpg" 10.96.10.40:5000/predict
    printf "\n--------------------------\n"
    curl -X POST -F "images=@/root/service_app/yorkshire_terrier_57.jpg" 10.96.10.50:5000/predict
    printf "\n--------------------------\n"
done