#!/bin/bash
export AWS_DEFAULT_PROFILE='rnd-account'
PACKER_AMI=$(grep artifact_id manifest.json | tr -d '." ,' | cut -d ":" -f3 |tail -1)
AMI_REGION=$(grep artifact_id manifest.json | tr -d '." ,' | cut -d ":" -f2|tail -1)

SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids $PACKER_AMI --region $AMI_REGION| grep "ImageId\|SnapshotId" | awk -F':' '{print $2}' | tr -d '"',',' | grep "snap")

#Deregistering AMI
aws ec2 deregister-image --image-id $PACKER_AMI --region $AMI_REGION && echo "AMI $PACKER_AMI Cleaned up."

#Deleting snapshots
for snapshot in $SNAPSHOT_IDS
do
        aws ec2 delete-snapshot --snapshot-id $snapshot --region $AMI_REGION && echo "Snapshot $SNAPSHOT_IDS Cleaned up."
done