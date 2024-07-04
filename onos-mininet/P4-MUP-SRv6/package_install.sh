docker exec -it  mininet sh
echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
chmod 1777 /tmp
rm -rf /var/lib/apt/lists/*
apt-get update &&   apt install bridge-utils 
