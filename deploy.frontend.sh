#!/bin/bash
##
# Deploys the front-end
##

txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellow
txtblu=$(tput setaf 4) # Blue
txtpur=$(tput setaf 5) # Purple
txtcyn=$(tput setaf 6) # Cyan
txtwht=$(tput setaf 7) # White
txtrst=$(tput sgr0) # Text reset

_DEBUG="on"

function EXECUTE() {
    [ "$_DEBUG" == "on" ] && echo $@ || $@
}

function title() {
    tput rev 
    showHeader $@
    tput sgr0
}

function showHeader() {
    input=$@
    echo ${txtgrn}
    printf "%0.s-" $(seq 1 ${#input})
    printf "\n"
    echo $input
    printf "%0.s-" $(seq 1 ${#input})
    echo ${txtrst}  
}

function showSectionTitle() {
    echo 
    echo ---  ${txtblu} $@ ${txtrst}  
    echo 
}

envnameuppercase=$(echo $envname | tr 'a-z' 'A-Z')
envnamelowercase=$(echo $envname | tr 'A-Z' 'a-z')
#-------------------------------------------
# Introduction
#-------------------------------------------
title "DEPLOYING THE FRONT-END FOR THE ENVIRONMENT $envnameuppercase"
## Fixing Cognito is required only for the workshop
#showHeader Fixing Cognito
#source fixcognito.sh
#-------------------------------------------
# Retrieving parameters from CloudFormation
#-------------------------------------------
apigtw=$(eval $(echo "aws cloudformation list-exports --query 'Exports[?contains(ExportingStackId,\`$envnameuppercase\`) && Name==\`apigtw\`].Value | [0]' | xargs -I {} echo {}"))
region=$(eval $(echo "aws cloudformation list-exports --query 'Exports[?contains(ExportingStackId,\`$envnameuppercase\`) && Name==\`region\`].Value | [0]' | xargs -I {} echo {}"))
url=$(eval $(echo "aws cloudformation list-exports --query 'Exports[?contains(ExportingStackId,\`$envnameuppercase\`) && Name==\`url\`].Value | [0]' | xargs -I {} echo {}"))
#-------------------------------------------
# Cloning the front end
#-------------------------------------------
showHeader "CLONING THE FRONT-END"
mkdir frontend
git clone https://github.com/fabianmartins/alienattack.application frontend
#-------------------------------------------
# UPDATING /resources/js/awsconfig.js
#-------------------------------------------
showHeader "UPDATING /resources/js/awsconfig.js"
cat <<END > ./frontend/resources/js/awsconfig.js
const DEBUG = true;
const AWS_CONFIG = {
    "region" : "$region",
    "API_ENDPOINT" : "$apigtw",
    "APPNAME" : "$envnameuppercase"
};
END
more ./frontend/resources/js/awsconfig.js
#-------------------------------------------
# DEPLOYING THE WEBSITE ON S3
#-------------------------------------------
showHeader "DEPLOYING THE WEBSITE ON S3"
aws s3 cp ./frontend s3://$envnamelowercase.app --recursive
#-------------------------------------------
# DELETING THE LOCAL VERSION
#-------------------------------------------
showHeader "DELETING THE LOCAL VERSION"
rm -rf ./frontend
#-------------------------------------------
# Finalization
#-------------------------------------------
title "Environment $envnameuppercase deployed"
if [ "$url" == "" ]; then
   echo "You DON'T have a CloudFront distribution deployed. Please deploy it."
else
   echo "URL: https://$url"
fi