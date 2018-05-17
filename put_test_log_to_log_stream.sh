#!/bin/sh

set -ex

NOW=$(gdate +"%Y-%m-%d %k:%M:%S")

if [[ -z ${TEST_LOG_MESSAGE} ]]; then
    TEST_LOG_MESSAGE="Hello Firehose! ${NOW}"
fi


mkdir -p ./tmp

cat <<-EOF > ./tmp/events.json
[
    {
        "timestamp": $(gdate --date="${NOW}" +%s%3N),
        "message": "${TEST_LOG_MESSAGE}"
    }
]
EOF

cat ./tmp/events.json | jq .

GROUP_NAME='/ex-aws-firehose'
STREAM_NAME='test'
SEQUENCE_TOKEN=$(aws logs describe-log-streams --log-group-name ${GROUP_NAME} --log-stream-name ${STREAM_NAME} --query 'logStreams[].uploadSequenceToken' --output text)

if [[ -z ${SEQUENCE_TOKEN} ]]; then
    aws logs put-log-events --log-group-name ${GROUP_NAME} --log-stream-name ${STREAM_NAME} --log-events file://tmp/events.json
else
    aws logs put-log-events --log-group-name ${GROUP_NAME} --log-stream-name ${STREAM_NAME} --log-events file://tmp/events.json --sequence-token $SEQUENCE_TOKEN
fi
