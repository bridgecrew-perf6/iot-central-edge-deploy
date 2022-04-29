#bin/bash
if [[ $# != 3 || "$1" == "" || "$2" == "" || "$3" == "" ]];
then
    echo "Scope ID, Registration ID, and the Symmetric Key are required"
    exit ${EXIT_CODES[2]}
fi

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

echo "Installing docker and containerd..."
sudo apt-get update;
sudo apt-get upgrade -y;
sudo apt-get install docker-ce docker-ce-cli containerd.io -y;
echo "Installed edge runtime..."
echo "Installing Nvidia-docker-2"
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y docker-ce nvidia-docker2
sudo systemctl restart docker
echo "Installed Nvidia-docker-2"
echo "Installing edge runtime"
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install iotedge=1.0.9* libiothsm-std=1.0.9*
echo "Create instance configuration 'config.yaml'."

SCOPE_ID=$1
REGISTRATION_ID=$2
SYMMETRIC_KEY=$3

echo "Set DPS provisioning parameters."

FILE_NAME="/etc/iotedge/config.yaml"
# create a config.toml - will replace existing
echo 'hostname = "'`hostname`'"' > $FILE_NAME
echo '' >> $FILE_NAME
echo '## DPS provisioning with symmetric key' >> $FILE_NAME
echo 'provisioning:' >> $FILE_NAME
echo 'source = "dps"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'global_endpoint = "https://global.azure-devices-provisioning.net"' >> $FILE_NAME
echo 'id_scope = "'$SCOPE_ID'"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'provisioning.attestation:' >> $FILE_NAME
echo 'method = "symmetric_key"' >> $FILE_NAME
echo 'registration_id = "'$REGISTRATION_ID'"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'symmetric_key = { value = "'$SYMMETRIC_KEY'" }' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'aziot_keys:' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'preloaded_keys:' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'cert_issuance:' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'agent:' >> $FILE_NAME
echo 'name = "edgeAgent"' >> $FILE_NAME
echo 'type = "docker"' >> $FILE_NAME
echo 'imagePullPolicy = "on-create"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'agent.config:' >> $FILE_NAME
echo 'image = "mcr.microsoft.com/azureiotedge-agent:1.1"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'agent.config.createOptions:' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'agent.env:' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'connect:' >> $FILE_NAME
echo 'workload_uri = "unix:///var/run/iotedge/workload.sock"' >> $FILE_NAME
echo 'management_uri = "unix:///var/run/iotedge/mgmt.sock"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'listen:' >> $FILE_NAME
echo 'workload_uri = "fd://iotedge.socket"' >> $FILE_NAME
echo 'management_uri = "fd://iotedge.mgmt.socket"' >> $FILE_NAME
echo 'min_tls_version = "tls1.0"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'watchdog:' >> $FILE_NAME
echo 'max_retries = "infinite"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'homedir: "/var/lib/iotedge"' >> $FILE_NAME
echo '' >> $FILE_NAME
echo 'moby_runtime:' >> $FILE_NAME
echo 'uri = "unix:///var/run/docker.sock"' >> $FILE_NAME
echo 'network = "azure-iot-edge"' >> $FILE_NAME
echo "Apply settings - this will restart the edge"
sudo systemctl restart iotedge
