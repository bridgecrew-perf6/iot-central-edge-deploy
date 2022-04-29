#bin/bash
#Display Help
Help()
{
   # Display Help
   echo "Scope ID, Device ID/Registration ID and Key are required"
   echo
   echo "Syntax: scriptTemplate [-ar|-rg|-pr]"
   echo "options:"
   echo "-sid     Scope ID"
   echo "-did     Device or Registration ID"
   echo "-key     Symmetric Key"
   echo "-ar      Azure Region (optional / default WUS2)"    
   echo "-rg      Resource Group Name (optional)"
   echo "-vmname  Name of new VM (optional)"
   echo "-vnet    Existing VNET to deploy into (optional)"
   echo "-subnet  Existing subnet in VNET (optional)"
   echo "-h       Show Help"
   echo
   exit;
}

if [ -z "$1" ]; then Help exit; fi

while [ ! -z "$1" ];
    do
        case "$1" in
        -sid) shift;SID=$1;;
        -did) shift;DID=$1;;
        -key) shift;KEY=$1;;
        -ar) shift;AZRG=$1;;
        -rg) shift;RGRP=$1;;
        -vmname) shift;VM=$1;;
        -vnet) shift;VN=$1;;
        -subnet) shift;SUB=$1;;
        -h) Help exit;;
    esac
    shift
done

SCOPEID=${SID}
DEVICEID=${DID}
SASKEY=${KEY}
REGION=${AZRG}
RESOURCEGROUP=${RGRP}
VMNAME=${VM}
VNET=${VN}
SUBNET=${SUB}

if [ -z "$SCOPEID" ]; then Help exit; fi
if [ -z "$DEVICEID" ]; then Help exit; fi
if [ -z "$SASKEY" ]; then Help exit; fi

if [ -z "$REGION" ]; then 
    REGION="westus2"
fi

if [ -z "$RESOURCEGROUP" ]; then 
    RESOURCEGROUP="rg-$(echo $random | md5sum | head -c 10; echo;)"
fi

if [ -z "$VMNAME" ]; then 
    VMNAME="vm-$(echo $random | md5sum | head -c 10; echo;)"
fi


#create resource group
# if [ $(az group exists --name $RESOURCEGROUP) = false ]; then
#     az group create --name $RESOURCEGROUP --location $REGION
# fi
az group create --name $RESOURCEGROUP --location $REGION

echo $RESOURCEGROUP
if [ -z "$VNET" ]; then
    echo "az vm create --resource-group $RESOURCEGROUP --name $VMNAME --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest --size Standard_NC6_Promo  --admin-username azureuser --generate-ssh-keys"
    az vm create --resource-group $RESOURCEGROUP --name $VMNAME --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen1:latest --size Standard_NC6_Promo  --admin-username azureuser --generate-ssh-keys
else
    echo "az vm create --resource-group $RESOURCEGROUP --name $VMNAME --vnet-name $VNET --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest --size Standard_DS2_v2  --admin-username azureuser --generate-ssh-keys"
    az vm create --resource-group $RESOURCEGROUP --name $VMNAME --vnet-name $VNET --subnet $SUBNET --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest --size Standard_DS2_v2  --admin-username azureuser --generate-ssh-keys
fi
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name NvidiaGpuDriverLinux \
  --publisher Microsoft.HpcCompute \
  --version 1.6

az vm extension set \
  --resource-group $RESOURCEGROUP \
  --vm-name $VMNAME \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --protected-settings "{\"fileUris\": [\"https://raw.githubusercontent.com/ms-us-rcg-app-innovation/iot-central-edge-deploy/main/iot-edge-config-bash.sh\"],\"commandToExecute\": \"sudo bash iot-edge-config-bash.sh $SCOPEID $DEVICEID $SASKEY\"}"