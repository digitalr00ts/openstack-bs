echo 'apt-get update' ; sudo apt-get update -qqy
sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes --assume-yes --no-install-recommends install vim
sudo apt-get --force-yes --assume-yes purge resolvconf

sudo sh -c "cat <<EOT >> /etc/network/interfaces
auto $PROV_ETH
iface $PROV_ETH inet manual
up ip link set dev \$IFACE up
down ip link set dev \$IFACE down
EOT"

sudo sh -c "cat <<EOT >> /etc/hosts

# controller
$IP_CONTROLLER		controller
# compute1
$IP_COMPUTE1		compute1
EOT"
