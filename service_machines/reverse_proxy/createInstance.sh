#!/bin/bash

while [[ "$#" -ge 1 ]]
do
key="$1"

case $key in
    -i|--image)
    IMAGENAME="$2"
    shift 
    ;; 
    -k|--key-name)
    KEYNAME="$2"
    shift 
    ;;   
    -u|--user-data)
    USERDATA="$2"
    shift 
    ;;
    -n|--nic-net-id)
    NICNETID="$2"
    shift 
    ;;
    -s|--security-groups)
    SECGROUPS="$2"
    shift 
    ;; 

    *)
            # unknown option
    ;;
esac
shift
done

if [ -z $IMAGENAME ]
then
   IMAGEID=`glance image-list | grep ubuntu_trusty | awk -F' \| ' '{ print $2 }'`
else
   IMAGEID=$(glance image-list | grep $IMAGENAME | awk -F' \| ' '{ print $2 }')
fi

FLAVOUR=`nova flavor-list | grep 's1.nano' | awk -F' \| ' '{ print $2 }'`

if [ -z $KEYNAME ]
then
   echo "A key name is required in the env var KEYNAME"
   exit 1
fi

if [ -z $USERDATA ]
then
   USERDATA=cloud-config.yaml
fi

if [ -z $SECGROUPS ]
then
   SECGROUPS=internal_openstack_net,Web-access-EBI-LAN,SSH-EBI-LAN
fi

if [ ! -z $NICNETID ]
then
   NETWORK='--nic net-id='$NICNETID
fi

mkdir -p auth

# Create user/password authentication
REGHTTPASS=auth/registry-htpasswd
read -s -p "Enter password to be set for user jenkins on the docker registry: " mypassword
read -s -p "Verify password to be set for user jenkins on the docker registry: " mypass_ver

if [ $mypassword==$mypass_ver ]
then
	docker run --rm --entrypoint htpasswd registry:2 -bn jenkins $mypassword > $REGHTTPASS
else
	echo "Passwords didn't match, exiting"
fi

# start an instance for the apache proxy, based on ubuntu trusty 14.04 server
nova boot --image $IMAGEID \
	--flavor $FLAVOUR --key-name $KEYNAME \
	--file /etc/apache2/htpasswd/registry-htpasswd=$REGHTTPASS $OTHERFILES \
	--security-groups $SECGROUPS --user-data $USERDATA $NETWORK proxy 
