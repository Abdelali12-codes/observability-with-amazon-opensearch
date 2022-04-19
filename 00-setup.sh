#!/bin/bash

# Disable Cloud9 AWS Manage Temporary Credentials
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

# Install jq
sudo yum -y -q install jq

# Update awscli
pip install --user --upgrade awscli

# Install awscli v2
curl -O "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" 
unzip -o awscli-exe-linux-x86_64.zip
sudo ./aws/install
rm awscli-exe-linux-x86_64.zip

# Install bash-completion
sudo yum -y install jq gettext bash-completion moreutils

# Configure AWS CLI
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

# Configure network variables (VPC, Priv/Pub-subnets)
export MyVPC=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='MyVPC'].OutputValue" --output text)
export PrivateSubnet1=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1'].OutputValue" --output text)
export PrivateSubnet2=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2'].OutputValue" --output text)
export PrivateSubnet3=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet3'].OutputValue" --output text)
export PublicSubnet1=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1'].OutputValue" --output text)
export PublicSubnet2=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2'].OutputValue" --output text)
export PublicSubnet3=$(aws cloudformation describe-stacks --stack-name Observability-AOS --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet3'].OutputValue" --output text)

echo "export MyVPC=${MyVPC}" | tee -a ~/.bash_profile
echo "export PrivateSubnet1=${PrivateSubnet1}" | tee -a ~/.bash_profile
echo "export PrivateSubnet2=${PrivateSubnet2}" | tee -a ~/.bash_profile
echo "export PrivateSubnet3=${PrivateSubnet3}" | tee -a ~/.bash_profile
echo "export PublicSubnet1=${PublicSubnet1}" | tee -a ~/.bash_profile
echo "export PublicSubnet2=${PublicSubnet2}" | tee -a ~/.bash_profile
echo "export PublicSubnet3=${PublicSubnet3}" | tee -a ~/.bash_profile

# Create a CMK for the EKS cluster to use when encrypting your Kubernetes secrets
aws kms create-alias --alias-name alias/observability-workshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/observability-workshop --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

# Reload bash_profile
source ~/.bash_profile

# Download lab repository
git clone https://github.com/rafael-gumiero/observability-aos
