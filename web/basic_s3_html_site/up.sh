#!/bin/bash

source .env

# Ensures that the site name is set
if [ -z "$BASIC_SITE" ]; then
  echo "Error: BASIC_SITE environment variable is not set."
  return
fi

# Creates the stack using the .env variable BASIC_SITE
# IAM capabilities is needed in order to ensure the policy is enacted.
echo "Creating stack: $BASIC_SITE"
aws cloudformation create-stack \
    --stack-name $BASIC_SITE \
    --template-body file://basic_s3_html_site.yaml \
    --parameters ParameterKey=StackName,ParameterValue=$BASIC_SITE \
    --capabilities CAPABILITY_IAM

# Pausing for the stack to be created.
echo "Waiting for stack to be created..."
aws cloudformation wait stack-create-complete --stack-name $BASIC_SITE


# This uses the JSOn query language to get the BUCKET_NAME so we can 
# output it to the terminal.
export BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $BASIC_SITE --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)

# Add our index.html to the newly created bucket.
echo "Uploading index.html to bucket: $BUCKET_NAME"
aws s3 cp ./index.html s3://$BUCKET_NAME/index.html --acl public-read

# We again use the query language to pull out the website url.
WEBSITE_URL=$(aws cloudformation describe-stacks --stack-name $BASIC_SITE --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" --output text)
echo "Website URL: $WEBSITE_URL"
