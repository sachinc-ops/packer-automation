#!/bin/bash
# Tag the AMI with Creator's IAM username
AMI_ID=$(grep artifact_id manifest.json | tr -d '." ,' | cut -d ":" -f3|tail -1)
AMI_REGION=$(grep artifact_id manifest.json | tail -1 | tr -d '." ,' | cut -d ":" -f2)
USER_NAME=$(aws sts get-caller-identity --query Arn --out text | cut -d '/' -f 2-3)

aws ec2 create-tags --region $AMI_REGION --resources $AMI_ID --tags Key=Created_by,Value=$USER_NAME
