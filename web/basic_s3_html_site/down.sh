#!/bin/bash

source .env

# Check if the BASIC_SITE environment variable is set.
if [ -z "$BASIC_SITE" ]; then
  echo "Error: BASIC_SITE environment variable is not set."
  return
fi

# Pull the bucket name from the description because we'll need it
# in order to empty and delete.
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $BASIC_SITE --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Could not retrieve bucket name from CloudFormation stack."
  return
fi

echo "Bucket to delete: $BUCKET_NAME"

# Empty the bucket.
echo "Emptying the bucket..."
aws s3 rm s3://$BUCKET_NAME --recursive

if [ $? -eq 0 ]; then
  echo "Bucket emptied successfully."
else
  echo "Error: Failed to empty the bucket. Proceeding with stack deletion anyway."
  return
fi

# Not sure if the **--force** is necessary.
echo "Attempting to force delete the bucket..."
aws s3 rb s3://$BUCKET_NAME --force

# Delete the CloudFormation stack. This will also delete the bucket, but
# only if it's empty.
echo "Deleting the CloudFormation stack..."
aws cloudformation delete-stack --stack-name $BASIC_SITE

# Wait for the stack to be deleted.
echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $BASIC_SITE

if [ $? -eq 0 ]; then
  echo "Stack and all resources (including the bucket) have been deleted successfully."
else
  echo "Error: Stack deletion failed or timed out. Please check the AWS CloudFormation console for more information."
fi
