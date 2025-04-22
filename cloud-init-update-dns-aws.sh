#!/usr/bin/env bash

set -e  # Exit on any error
set -o pipefail

# Variables
AWS_REGION="il-central-1"
HOSTED_ZONE_NAME="aws.cts.care"
TTL=300

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$HOSTED_ZONE_NAME" \
  --query "HostedZones[0].Id" --output text | sed 's#/hostedzone/##')

# Get metadata token
echo "Fetching EC2 metadata token..."
TOKEN=$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 300" \
        http://169.254.169.254/latest/api/token)

# Get instance ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id \
        -H "X-aws-ec2-metadata-token: $TOKEN")

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Error: Unable to retrieve instance ID."
  exit 1
fi

echo "Found instance ID: $INSTANCE_ID"

# Get public IP
echo "Fetching public IP..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 \
        -H "X-aws-ec2-metadata-token: $TOKEN")

if [[ -z "$PUBLIC_IP" ]]; then
  echo "Error: Unable to retrieve public IP."
  exit 1
fi

echo "Public IP is: $PUBLIC_IP"

# Get the Owner tag to build the record name
echo "Fetching Owner tag for instance..."
OWNER_NAME=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].Tags[?Key=='Owner'].Value | [0]" \
  --output text)

if [[ -z "$OWNER_NAME" || "$OWNER_NAME" == "None" ]]; then
  echo "Error: Owner tag not found."
  exit 1
fi

# Build the full record name
RECORD_NAME="$OWNER_NAME.$HOSTED_ZONE_NAME"
echo "Record name will be: $RECORD_NAME"

# Check current IP in Route53
echo "Checking current Route53 record..."
CURRENT_ROUTE53_IP=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --region "$AWS_REGION" \
  --query "ResourceRecordSets[?Name == '${RECORD_NAME}.'].ResourceRecords[0].Value" \
  --output text)

echo "Current Route53 IP: $CURRENT_ROUTE53_IP"

# Compare and update if needed
if [[ "$PUBLIC_IP" != "$CURRENT_ROUTE53_IP" && -n "$PUBLIC_IP" ]]; then
  echo "Updating Route53 record with new IP..."
  cat > change-batch.json <<EOF
{
  "Comment": "Update record to new IP",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": $TTL,
        "ResourceRecords": [
          {
            "Value": "$PUBLIC_IP"
          }
        ]
      }
    }
  ]
}
EOF

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file://change-batch.json \
    --region "$AWS_REGION"

  echo "Route53 DNS record updated successfully."

  # Cleanup
  rm -f change-batch.json
else
  echo "No update needed. IP has not changed."
fi
