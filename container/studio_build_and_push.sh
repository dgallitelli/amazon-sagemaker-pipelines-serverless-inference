#!/usr/bin/env bash

image=$1

ACCOUNT_ID=$(aws sts get-caller-identity --query Account | tr -d '"')
AWS_REGION=$(aws configure get region)
TAG=$(date +%Y%m%d%H%M%S)

fullname="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${image}:${TAG}"

# If the repository doesn't exist in ECR, create it.
aws ecr describe-repositories --repository-names "${image}" > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
    aws ecr create-repository --repository-name "${image}" > /dev/null
fi

# Get the login command from ECR and execute it directly
# $(aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com)

# Build the docker image locally and then push it to ECR with the full name.
cd docker

# Check and/or Install sm-docker
IMAGE_BUILDER_FLAG=$(pip list | grep sagemaker-studio-image-build | wc -l)
if [[$IMAGE_BUILDER_FLAG = 0]]
then
    echo "Installing sm-docker ... "
    pip install sagemaker-studio-image-build
else
    echo "sagemaker-studio-image-build already installed - skipping."
fi

echo "Using sm-docker to build and push ${image}"
sm-docker build . --repository ${image}:${TAG}