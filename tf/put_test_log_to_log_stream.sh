#!/bin/sh

set -ex

TEST_LOG_MESSAGE=${1:-'Hellow Firehose!'}
NOW=$(gdate +"%Y-%m-%d %k:%M:%S")

cat <<-EOF > events.json
[
    {
        "timestamp": $(gdate --date="${NOW}" +%s%3N),
        "message": "${TEST_LOG_MESSAGE}"
    }
]
EOF

cat events.json | jq .

aws logs put-log-events --log-group-name /ex-aws-firehose --log-stream-name test --log-events file://events.json
