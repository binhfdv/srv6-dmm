ovs-vsctl del-br $1
ovs-vsctl add-br $1
ifconfig $1 up
ovs-vsctl add-port $1 $2
ifconfig $2 0
ifconfig $1 $3 up
