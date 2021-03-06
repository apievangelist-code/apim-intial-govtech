#!/bin/bash

# Load variables
source "conf/variables"

# Login to the docker registry
docker login  https://${REPO_URL} --username ${REPO_USERNAME} --password ${REPO_PASSWORD}

# Generate Topology certs
if [[ -f ${CERTS_DIR}/${ENV}-key.pem ]] && [[ -f ${CERTS_DIR}/${ENV}-cert.pem ]]
then
    echo "Topology certs already exists!"
    echo "adding cert_pass.txt"
    echo "${CERT_PASS}" > "${CERTS_DIR}/cert_pass.txt"
else
    echo "[INFO] ============================================================"
    echo "[INFO]  Creating domain Certificate for ${ENV}"
    echo "[INFO] ============================================================"

    echo "[INFO] creating password file to use in certificate generation..."
    echo "${CERT_PASS}" > "${CERTS_DIR}/cert_pass.txt"
    if [[ -z "${CERT_PASS}" || ! -f "${CERTS_DIR}/cert_pass.txt" ]]; then
        echo "[ERROR] Password not found"
        exit 1
    fi

    echo "[INFO] Running EMT script to generate certificate"
    if ! "${EMT_DIR}/gen_domain_cert.py" \
        --domain-id "${ENV}" \
        --pass-file "${CERTS_DIR}/cert_pass.txt" \
        --OU "${CERT_ORGUNIT}" \
        --O "${CERT_ORG}" \
        --sign-alg ${CERT_SIGN_ALG} \
        --force; then
        echo "[ERROR] Domain certicate creation failed, abort!"
        exit 1
    else
        echo "[INFO] certificate has been generated successfully"
        mv ${EMT_DIR}/certs/${ENV}/* ${CERTS_DIR}/
    fi
fi

# Build base image
echo "[INFO] Check if Docker image already exist"
if ! docker image pull ${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG}
then
    echo "Docker image ${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} doesn't exist on repo."
    echo "[INFO] Running EMT script to create base image"
    if ! "${EMT_DIR}/build_base_image.py" \
        --installer=${SOURCE_DIR}/APIGateway_${APIM_VERSION}.${APIM_RELEASE}_Install_linux-x86-64_BN02.run \
        --out-image=${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} \
        --os=${OS}; then
        echo "[ERROR] Domain certicate creation failed, abort!"
        exit 1
    else
        echo "[INFO] Base image has been generated successfully"
    fi
else
    echo "Image ${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} already exist"
fi

# Build anm image
echo "[INFO] Check if Docker image already exist"
if ! docker image pull ${REPO_URL}/${REPO_PATH}/${ANM_OUTPUT_NAME}:${ANM_BUILDTAG}
then
    echo "[INFO]============================================"
    echo "[INFO] Creating ANM Image"
    echo "[INFO]============================================"

    echo "[INFO] Creating merge path"
    mkdir -p ${ANM_MERGE_DIR}/ext/lib ${ANM_MERGE_DIR}/system/conf
    echo "[INFO] Add External library"
    cp ${SOURCE_DIR}/mysql-connector-java-*.jar ${ANM_MERGE_DIR}/ext/lib
    #Merge JAR librarie to add env modules
    cp ${SOURCE_DIR}/apim-env-module-*.jar ${ANM_MERGE_DIR}/ext/lib
    #Add HTTP1.1 connection for istio compatibility
    cp ${SOURCE_DIR}/nodemanager.xml ${ANM_MERGE_DIR}/system/conf

    echo "[INFO] Creating ANM pass file"
    anmPassFile="${TMP_DIR}/anm_pass.txt"
    echo  ${ANM_PASSWORD} > ${anmPassFile}

    echo "[INFO]Running command to create image"
    if ! "${EMT_DIR}/build_anm_image.py" \
        --out-image=${REPO_URL}/${REPO_PATH}/${ANM_OUTPUT_NAME}:${ANM_BUILDTAG} \
        --parent-image=${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} \
        --domain-cert="${CERTS_DIR}/${ENV}-cert.pem" \
        --domain-key="${CERTS_DIR}/${ENV}-key.pem" \
        --domain-key-pass-file="${CERTS_DIR}/cert_pass.txt" \
        --fed=apiprojects/${ANM_OUTPUT_NAME}-${ANM_FED_VERSION}.fed \
        --healthcheck \
        --metrics \
        --merge-dir=${ANM_MERGE_DIR} \
        --anm-username=${ANM_USERNAME} \
        --anm-pass-file=${anmPassFile} ; then
        echo "[ERROR] Unable to create Image"
        exit 1
    else
        echo "[INFO] Image created Successfully"
        # clean temp folder
        rm -Rf temp
    fi
else
    echo "Image ${REPO_URL}/${REPO_PATH}/${ANM_OUTPUT_NAME}:${ANM_BUILDTAG} already exist"
fi

# Build GTW INT image
    echo "[INFO]============================================"
    echo "[INFO] Creating GTW INT Image"
    echo "[INFO]============================================"

    echo ${CERT_PASS} > "${TMP_DIR}/cert_pass.txt"

    echo "[INFO] Creating merge path"
    mkdir -p ${GTW_MERGE_DIR}/ext/lib
    cp ${SOURCE_DIR}/mysql-connector-java-*.jar ${GTW_MERGE_DIR}/ext/lib
    #Merge JAR librarie to add env modules
    cp ${SOURCE_DIR}/apim-env-module-*.jar ${GTW_MERGE_DIR}/ext/lib

    echo "[INFO]Running command to create image"
    if ! "${EMT_DIR}/build_gw_image.py" \
        --out-image ${REPO_URL}/${REPO_PATH}/${GTW_INT_OUTPUT_NAME}:${GTW_INT_BUILDTAG} \
        --parent-image=${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} \
        --domain-cert="${CERTS_DIR}/${ENV}-cert.pem" \
        --domain-key="${CERTS_DIR}/${ENV}-key.pem" \
        --domain-key-pass-file="${CERTS_DIR}/cert_pass.txt" \
        --fed=${FED_DIR}/${GTW_INT_OUTPUT_NAME}-${GTW_INT_FED_VERSION}.fed \
        --license="${SOURCE_DIR}/API-7.7-Docker-Temp.lic" \
        --group-id="${APIM_GRP_INT_NAME}" \
        --merge-dir=${GTW_MERGE_DIR}; then
        echo "[ERROR] Unable to create Image "
        exit 1
    else
        echo "[INFO] Image created Successfully "
        # clean temp folder
        rm -Rf temp
    fi


# Build GTW EXT image
    echo "[INFO]============================================"
    echo "[INFO] Creating GTW EXT Image"
    echo "[INFO]============================================"

    echo ${CERT_PASS} > "${TMP_DIR}/cert_pass.txt"

    echo "[INFO] Creating merge path"
    mkdir -p ${GTW_MERGE_DIR}/ext/lib
    cp ${SOURCE_DIR}/mysql-connector-java-*.jar ${GTW_MERGE_DIR}/ext/lib
    #Merge JAR librarie to add env modules
    cp ${SOURCE_DIR}/apim-env-module-*.jar ${GTW_MERGE_DIR}/ext/lib

    echo "[INFO]Running command to create image"
    if ! "${EMT_DIR}/build_gw_image.py" \
        --out-image ${REPO_URL}/${REPO_PATH}/${GTW_EXT_OUTPUT_NAME}:${GTW_EXT_BUILDTAG} \
        --parent-image=${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG} \
        --domain-cert="${CERTS_DIR}/${ENV}-cert.pem" \
        --domain-key="${CERTS_DIR}/${ENV}-key.pem" \
        --domain-key-pass-file="${CERTS_DIR}/cert_pass.txt" \
        --fed=${FED_DIR}/${GTW_EXT_OUTPUT_NAME}-${GTW_EXT_FED_VERSION}.fed \
        --license="${SOURCE_DIR}/API-7.7-Docker-Temp.lic" \
        --group-id="${APIM_GRP_EXT_NAME}" \
        --merge-dir=${GTW_MERGE_DIR}; then
        echo "[ERROR] Unable to create Image "
        exit 1
    else
        echo "[INFO] Image created Successfully "
        # clean temp folder
        rm -Rf temp
    fi

# Push images
    docker push ${REPO_URL}/${REPO_PATH}/${BASE_IMAGE_NAME}:${BASE_BUILDTAG}
    docker push ${REPO_URL}/${REPO_PATH}/${ANM_OUTPUT_NAME}:${ANM_BUILDTAG}
    docker push ${REPO_URL}/${REPO_PATH}/${GTW_EXT_OUTPUT_NAME}:${GTW_EXT_BUILDTAG}
    docker push ${REPO_URL}/${REPO_PATH}/${GTW_INT_OUTPUT_NAME}:${GTW_INT_BUILDTAG}