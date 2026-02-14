#!/bin/bash
# itsm_add_note.sh <note>
BUCKET="$1"
KEY="$2"
NOTE="$3"

tmp=$(mktemp)
aws s3 cp s3://$BUCKET/$KEY $tmp
jq --arg note "$NOTE" '.work_notes += [$note] | .status = "Investigating"' $tmp > ${tmp}.out
aws s3 cp ${tmp}.out s3://$BUCKET/$KEY
rm -f $tmp ${tmp}.out
