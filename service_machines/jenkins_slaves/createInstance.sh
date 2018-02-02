#!/bin/bash


DOCKER_REGISTRY_IP=$1

if [ -z ${DOCKER_REGISTRY_IP} ]
then
	echo 'Cannot find a machine named pmnl_docker_registry to get the ip from in your tenancy'
	nova list --fields name,networks
else
        echo 'Using registry ip $DOCKER_REGISTRY_IP found in your tenancy for machine pmnl_docker_registry'
fi


NEW_UUID=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)

#REGISTRYCACERT=put_registry_certificate_here/registry_cacert.crt

if [ -f $REGISTRYCACERT ]
then
   COPYCERTIFICATE="--file /home/ubuntu/registry_cacert.crt="$REGISTRYCACERT
   sed s/LOCALREGISTRY_IP/${DOCKER_REGISTRY_IP//[$'\t\r\n ']}/ cloud-config.template.yaml | sed s/\#CERTS\#/\-/ > cloud-config.yaml
else
   sed s/LOCALREGISTRY_IP/${DOCKER_REGISTRY_IP//[$'\t\r\n ']}/ cloud-config.template.yaml | sed s/\#NOCERTS\#/\-/ > cloud-config.yaml
fi

IMAGE=`nova image-list | grep Ubuntu16.04 | awk -F' \| ' '{ print $2 }'`
FLAVOUR=`nova flavor-list | grep 's1.large' | awk -F' \| ' '{ print $2 }'`
KEYNAME='phenomenal-ci-slaves'

echo "Calling nova with image $IMAGE, flavor $FLAVOUR and key $KEYNAME"

# start an instance for Jenkins based on Ubuntu 14.04 LTS, mounting the jenkins-data volume.
nova boot --image $IMAGE \
	--flavor $FLAVOUR --key-name $KEYNAME \
	--user-data cloud-config.yaml jenkins_slave_$NEW_UUID > jenkins_slave_$NEW_UUID.log

# --security-groups internal_openstack_net 
# for cloud-init output on the slave machine, look into: /var/log/cloud-init-output.log
