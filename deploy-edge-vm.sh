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
   echo "-ar      Azure Region (optional / default EUS2)"    
   echo "-rg      Resource Group Name (optional)"
   echo "-vmname  Name of new VM (optional)"
   echo "-h      Show Help"
   echo
   exit;
}

if [ -z "$1" ]; then Help exit; fi

while [ ! -z "$1" ];
    do
        case "$1" in
        -sid) shift;SCOPEID=$1;;
        -did) shift;DEVICEID=$1;;
        -key) shift;SASKEY=$1;;
        -ar) shift;REGION=$1;;
        -rg) shift;RESOURCEGROUP=$1;;
        -vmname) shift;VMNAME=$1;;
        -h) Help exit;;
    esac
    shift
done

if [ ! -z "$SCOPEID" ]; then Help exit; fi
if [ ! -z "$DEVICEID" ]; then Help exit; fi
if [ ! -z "$SASKEY" ]; then Help exit; fi

if [ ! -z "$REGION" ]; then 
    $REGION="eus2"
fi

if [ ! -z "$RESOURCEGROUP" ]; then 
    $RESOURCEGROUP="rg-$(echo $random | md5sum | head -c 10; echo;)"
fi

if [ ! -z "$VMNAME" ]; then 
    $VMNAME="vm-$(echo $random | md5sum | head -c 10; echo;)"
fi

#create resource group
if [ $(az group exists --name $RESOURCEGROUP) = false ]; then
    az group create --name $RESOURCEGROUP --location $REGION
fi

az vm create --resource-group $RESOURCEGROUP --name $VMNAME --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest --size Standard_DS2_v3  --admin-username azureuser --generate-ssh-keys
az vm extension set \
  --resource-group exttest \
  --vm-name exttest \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --protected-settings "{\"fileUris\": [\"https://raw.githubusercontent.com/ms-us-rcg-app-innovation/iot-central-edge-deploy/main/iot-edge-config-bash.sh\"],\"commandToExecute\": \"sudo bash iot-edge-config-bash.sh $SCOPEID $DEVICEID $SASKEY\"}"