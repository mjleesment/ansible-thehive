#!/bin/bash

# Must be run with org-admin account inside thehive_main container
org_admin_accoount=""
password=""

curl -XPUT -u"$org_admin_accoount":"$password" -H 'Content-type: application/json' http://127.0.0.1:9000/api/config/organisation/notification -d '
{
  "value": [
    {
      "delegate": false,
      "trigger": { "name": "AnyEvent"},
      "notifier": { "name": "webhook", "endpoint": "slack" }
    }
  ]
}'
