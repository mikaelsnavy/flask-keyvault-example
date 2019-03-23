# Introduction

This repository is made for a test of [Flask-KeyVault](https://pypi.org/project/Flask-KeyVault/). 


# Docker Image Build and Publish

```bash
docker build -t printenv .
docker tag printenv mikaelsnavy/printenv
```

# Environment Deploy


# NOTES

Currently, the `flask-keyvault` package isn't being installed via pip, but is integrated in this repository as we work out some bugs. 