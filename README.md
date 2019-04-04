# Introduction

This repository is made for a test and example of [Flask-KeyVault](https://pypi.org/project/Flask-KeyVault/). One particulary good use case of Flask-KeyVault is pulling Flask configuration values from KayVault so this is our test use in this project.


# Docker Image Build and Publish

Prior to deploying the environment, ensure you have your docker image published for the App Service to pull from!

```bash
docker build -t flask-keyvault-example .
docker tag flask-keyvault-example mikaelsnavy/flask-keyvault-example
docker push mikaelsnavy/flask-keyvault-example
```


# Environment Deploy

After building and publishing your docker image, you can proceed in deploying the test environment. NOTE - this relies on [Terraform](https://www.terraform.io/) and the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

Terraform will authenticate using the Azure CLI. Make sure to run `az login` before trying to deploy infrastructure through Terraform. The current CLI user must also be passed in order to give KeyVault access to populate our test secret.

```bash
cd terraform/
terraform init
terraform plan -var 'az_cli_user=mistadde@microsoft.com' -out "plan"
terraform apply "plan"
```


# NOTES

Currently, the `flask-keyvault` package isn't being installed via pip, but is integrated in this repository as we work out some bugs. 