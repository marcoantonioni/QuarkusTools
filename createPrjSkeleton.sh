#!/bin/bash

APP_NAME=""
PRJ_GROUP=marco.demos.tests

# https://maven.repository.redhat.com/ga/com/redhat/quarkus/platform/quarkus-maven-plugin/
RH_QM_PLUGIN_VER="2.7.6.Final-redhat-00011"

K8S=false

usage () {
    echo -e "Usage:\n"
    echo "createPrjSkeleton.sh -a <app-name> -g <group-name> -q [optional]\"<RH Quarkus maven plugin version>\" -k [optional k8s extensions]<true|false>"
    echo -e "\nexample: ./createPrjSkeleton.sh -a MyApp -g ${PRJ_GROUP} -q \"${RH_QM_PLUGIN_VER}\" -k true"
    echo "List of available RH Quarkus maven plugin version"
    curl -s https://maven.repository.redhat.com/ga/com/redhat/quarkus/platform/quarkus-maven-plugin/ | grep Final | sed 's/.*href="//g' | sed 's/\/".*//g' | sort
    exit 
}


# read params
while getopts "a:g:q:k:h:" flag
do
    case "${flag}" in
        a) APP_NAME=${OPTARG};;
        g) PRJ_GROUP=${OPTARG};;
        q) RH_QM_PLUGIN_VER=${OPTARG};;
        k) K8S=${OPTARG};;
        h) usage;;
    esac
done

# verify plugin version
if [[ ! -z ${RH_QM_PLUGIN_VER} ]]; then
    PLUGIN_VER_EXIST=$(curl -s https://maven.repository.redhat.com/ga/com/redhat/quarkus/platform/quarkus-maven-plugin/ | grep Final | sed 's/.*href="//g' | sed 's/\/".*//g' | grep ${RH_QM_PLUGIN_VER})
    if [[ -z ${PLUGIN_VER_EXIST} ]]; then
        RH_QM_PLUGIN_VER=""
    fi
fi

# if wrong plugin version
if [[ -z ${RH_QM_PLUGIN_VER} ]]; then
    echo -e "\nError wrong plugin version, list of available versions of RH Quarkus maven plugin"
    curl -s https://maven.repository.redhat.com/ga/com/redhat/quarkus/platform/quarkus-maven-plugin/ | grep Final | sed 's/.*href="//g' | sed 's/\/".*//g' | sort
    usage
fi

if [[ -z ${APP_NAME} ]]; then
    echo "Error app name must not be empty."
    usage
else
    # if folder exists error
    if [ -d ./${APP_NAME} ];
    then
        echo "Error directory ./${APP_NAME} already exists."
        exit
    fi    
fi

if [[ -z ${PRJ_GROUP} ]]; then
    echo "Error project group name must not be empty."
    usage
fi

mvn com.redhat.quarkus.platform:quarkus-maven-plugin:${RH_QM_PLUGIN_VER}:create \
	-DprojectGroupId=${PRJ_GROUP} \
	-DprojectArtifactId=${APP_NAME} \
	-DplatformGroupId=com.redhat.quarkus.platform \
	-DplatformVersion=${RH_QM_PLUGIN_VER}

cd ${APP_NAME}
quarkus ext add org.kie.kogito:kogito-quarkus
quarkus ext add quarkus-resteasy-jackson
quarkus ext add io.quarkus:quarkus-smallrye-openapi
if [[ ${K8S} == "true" ]];
then
    quarkus ext add io.quarkus:quarkus-smallrye-health
fi

