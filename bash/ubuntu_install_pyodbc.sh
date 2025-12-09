#!/bin/bash

# This script installs pyodbc and its dependencies on an Ubuntu system.

# halt on errors
set -e

# Install ODBC development libraries

# only if not already installed
if ! dpkg -s packages-microsoft-prod &> /dev/null; then
  # https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver17&tabs=alpine18-install%2Cdebian17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline
  curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
fi

# only if not already installed
if ! dpkg -s msodbcsql17 &> /dev/null; then
  sudo apt-get update
  sudo ACCEPT_EULA=Y apt-get install -y unixodbc-dev msodbcsql17
fi

# Install pyodbc via pip
# only if not already installed:
if ! python -c "import pyodbc" &> /dev/null; then
  pip install pyodbc
fi

# might need to install pyodbc using apt-get for some systems
# sudo apt-get install -y python3-pyodbc
