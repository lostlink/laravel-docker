#!/bin/bash

# Load environment variables if .mailparse.env exists
if [ -f /usr/local/bin/.mailparse.env ]; then
    . /usr/local/bin/.mailparse.env
fi

# Redirect stdout and stderr to Docker logs
#exec > >(tee -a /proc/1/fd/1)
#exec 2> >(tee -a /proc/1/fd/2)

# Configuration from environment variables
KINESIS_STREAM_NAME="${KINESIS_STREAM_NAME:-}"
KINESIS_REGION="${KINESIS_REGION:-}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
FORWARD_EMAIL="${FORWARD_EMAIL:-}"
DOMAIN_FILTER="${DOMAIN_FILTER:-msg.domaineasy.com}"
REMOVE_TEMP_EMAIL="${REMOVE_TEMP_EMAIL:-true}"

# Log the incoming email for debugging purposes
echo "Email received at $(date)"

# Save the email content to a temporary file
TEMP_EMAIL_FILE=$(mktemp /tmp/email_XXXXXX.eml)

# Capture the email content
cat > "$TEMP_EMAIL_FILE"

# Extract relevant information from the email
subject=$(grep -i "^Subject:" "$TEMP_EMAIL_FILE" | sed 's/Subject: //')
from=$(grep -i "^From:" "$TEMP_EMAIL_FILE" | sed 's/From: //')
to=$(grep -i "^To:" <<< "$email_content" | sed 's/To: //')

# Log the extracted information
echo "Received an email from: $from to $to with subject: $subject"

# Check if the 'To' field matches the specified domain
if [ -n "$DOMAIN_FILTER" ] && ! grep -iq "^To:.*@$DOMAIN_FILTER" "$TEMP_EMAIL_FILE"; then
    echo "Email does not match the 'To' domain '$DOMAIN_FILTER'. Ignoring."

    # Conditionally remove the temp email file based on the REMOVE_TEMP_EMAIL variable
    if [ "$REMOVE_TEMP_EMAIL" = "true" ]; then
        rm -f "$TEMP_EMAIL_FILE"
    fi
    exit 0
fi

# Read the entire email content
email_content=$(cat "$TEMP_EMAIL_FILE")

# Cleanup: Conditionally remove the temporary email file
if [ "$REMOVE_TEMP_EMAIL" = "true" ]; then
    rm -f "$TEMP_EMAIL_FILE"
fi

# Function to send email to Kinesis
send_to_kinesis() {
    . /usr/local/bin/venv/bin/activate;

    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Cannot send email to Kinesis."
        return 1
    fi

    # Construct JSON payload
    email_json=$(jq -n \
        --arg from "$from" \
        --arg to "$(grep -i "^To:" <<< "$email_content" | sed 's/To: //')" \
        --arg subject "$subject" \
        --arg date "$(grep -i "^Date:" <<< "$email_content" | sed 's/Date: //')" \
        --arg reply_to "$(grep -i "^Reply-To:" <<< "$email_content" | sed 's/Reply-To: //')" \
        --arg raw_email "$email_content" \
        '{
            "from": $from,
            "to": $to,
            "subject": $subject,
            "date": $date,
            "reply_to": $reply_to,
            "data": $raw_email
        }')

    aws kinesis put-record \
        --stream-name "$KINESIS_STREAM_NAME" \
        --data "$email_json" \
        --partition-key "$from" \
        --region "$KINESIS_REGION"

    if [ $? -eq 0 ]; then
        echo "Email successfully sent to Kinesis stream."
        return 0
    else
        echo "Failed to send email to Kinesis stream."
        return 1
    fi
}

# Function to send email to a webhook
send_to_webhook() {
    if ! command -v curl &> /dev/null; then
        echo "cURL not found. Cannot send email to webhook."
        return 1
    fi

    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: text/plain" \
        --data-binary "$email_content"

    if [ $? -eq 0 ]; then
        echo "Email successfully sent to webhook."
        return 0
    else
        echo "Failed to send email to webhook."
        return 1
    fi
}

# Function to forward email to another address
forward_email() {
    if ! command -v sendmail &> /dev/null; then
        echo "Sendmail not found. Cannot forward email."
        return 1
    fi

    echo "$email_content" | sendmail -t "$FORWARD_EMAIL"

    if [ $? -eq 0 ]; then
        echo "Email successfully forwarded to $FORWARD_EMAIL."
        return 0
    else
        echo "Failed to forward email to $FORWARD_EMAIL."
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
    echo "No valid configuration found. Email content logged and discarded."
fi

# Exit with the result status
exit $result