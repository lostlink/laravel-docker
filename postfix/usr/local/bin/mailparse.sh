#!/bin/bash

# Configuration from environment variables
KINESIS_STREAM_NAME="${KINESIS_STREAM_NAME:-}"
KINESIS_REGION="${KINESIS_REGION:-}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
FORWARD_EMAIL="${FORWARD_EMAIL:-}"

# Log the incoming email for debugging purposes
echo "Email received at $(date)" >> /proc/1/fd/1

# Save the email content to a temporary file
TEMP_EMAIL_FILE=$(mktemp /tmp/email_XXXXXX.eml)

# Capture the email content
cat > "$TEMP_EMAIL_FILE"

# Extract relevant information from the email
subject=$(grep -i "^Subject:" "$TEMP_EMAIL_FILE" | sed 's/Subject: //')
from=$(grep -i "^From:" "$TEMP_EMAIL_FILE" | sed 's/From: //')

# Log the extracted information (optional)
echo "Received an email from: $from with subject: $subject" >> /proc/1/fd/1

# Read the entire email content
email_content=$(cat "$TEMP_EMAIL_FILE")

# Cleanup: remove the temporary email file as soon as possible
rm -f "$TEMP_EMAIL_FILE"

# Function to send email to Kinesis
send_to_kinesis() {
    . /root/venv/bin/activate;

    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Cannot send email to Kinesis." >> /proc/1/fd/1
        return 1
    fi

    aws kinesis put-record \
        --stream-name "$KINESIS_STREAM_NAME" \
        --data "$email_content" \
        --partition-key "$from" \
        --region "$KINESIS_REGION"

    if [ $? -eq 0 ]; then
        echo "Email successfully sent to Kinesis stream." >> /proc/1/fd/1
        return 0
    else
        echo "Failed to send email to Kinesis stream." >> /proc/1/fd/1
        return 1
    fi
}

# Function to send email to a webhook
send_to_webhook() {
    if ! command -v curl &> /dev/null; then
        echo "cURL not found. Cannot send email to webhook." >> /proc/1/fd/1
        return 1
    fi

    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: text/plain" \
        --data-binary "$email_content"

    if [ $? -eq 0 ]; then
        echo "Email successfully sent to webhook." >> /proc/1/fd/1
        return 0
    else
        echo "Failed to send email to webhook." >> /proc/1/fd/1
        return 1
    fi
}

# Function to forward email to another address
forward_email() {
    if ! command -v sendmail &> /dev/null; then
        echo "Sendmail not found. Cannot forward email." >> /proc/1/fd/1
        return 1
    fi

    echo "$email_content" | sendmail -t "$FORWARD_EMAIL"

    if [ $? -eq 0 ]; then
        echo "Email successfully forwarded to $FORWARD_EMAIL." >> /proc/1/fd/1
        return 0
    else
        echo "Failed to forward email to $FORWARD_EMAIL." >> /proc/1/fd/1
        return 1
    fi
}

# Initialize result to success
result=0

# Perform the configured actions
if [ -n "$KINESIS_STREAM_NAME" ] && [ -n "$KINESIS_REGION" ]; then
    send_to_kinesis
    result=$((result + $?))
fi

if [ -n "$WEBHOOK_URL" ]; then
    send_to_webhook
    result=$((result + $?))
fi

if [ -n "$FORWARD_EMAIL" ]; then
    forward_email
    result=$((result + $?))
fi

# Log if no actions were performed
if [ "$result" -eq 0 ] && [ -z "$KINESIS_STREAM_NAME" ] && [ -z "$WEBHOOK_URL" ] && [ -z "$FORWARD_EMAIL" ]; then
    echo "No valid configuration found. Email content logged and discarded." >> /proc/1/fd/1
fi

# Exit with the result status
exit $result