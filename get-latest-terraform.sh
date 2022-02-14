#!/bin/bash
#
# https://github.com/sskalnik/tf-updater
#
# If there's a new Terraform release available, delete the current Terraform install and download the new one.
# Works even if Terraform is not installed!

LATEST_RELEASE_TAG=$(curl https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)
LATEST_RELEASE=$(awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }' <<< "$LATEST_RELEASE_TAG")

# Install if Terraform not found, by declaring Terraform version to be 0
if ! type "terraform" > /dev/null 2>&1; then
  CURRENT_TF_VERSION=0
else
  CURRENT_TF_VERSION=$(terraform -v | awk 'NR==1{print $NF}' | cut -c 2- | awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }')
fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  OS=linux
else
  OS=$OSTYPE
fi

if [ "${LATEST_RELEASE}" -gt "${CURRENT_TF_VERSION}" ]; then
   echo "Installing Terraform ${LATEST_RELEASE_TAG} for ${OS}..."
   cd /tmp/ || exit
   wget -q "https://releases.hashicorp.com/terraform/${LATEST_RELEASE_TAG}/terraform_${LATEST_RELEASE_TAG}_${OS}_amd64.zip"
   sudo rm -f /usr/local/bin/terraform
   sudo unzip "terraform_${LATEST_RELEASE_TAG}_${OS}_amd64.zip" -d /usr/local/bin
   sudo chmod +x /usr/local/bin/terraform
   sudo mv /usr/local/bin/terraform "/usr/local/bin/terraform${LATEST_RELEASE_TAG}"
   sudo ln -s "/usr/local/bin/terraform${LATEST_RELEASE_TAG}" /usr/local/bin/terraform
   rm -f "terraform_${LATEST_RELEASE_TAG}_${OS}_amd64.zip"
   cd -
else
   echo "Latest Terraform already installed."
fi
