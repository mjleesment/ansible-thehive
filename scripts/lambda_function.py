# https://github.com/ReconInfoSec/thehive-slack-webhook

from __future__ import print_function
import json
import logging
import os
import time
import config as cfg
from base64 import b64decode
import requests
from flask import Flask, request
#from urllib2 import Request, urlopen, URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = Flask(__name__)

def add_object(title,value,short):
    object = {"title": title,"value": value,"short": short}
    return object


def process_event(event):
    logger.info("Processing event: %s", event)
    fields = []
    titleLink = False
    objectType = ""
    caseId = None
    caseLink = ""
    titleLink = ""

    if "Delete" not in event['operation']:
        if event['objectType'] == "case":
            objectType = "Case"
            caseId = event['object']['number']
            fields.append(add_object("Case #", caseId, True))
            caseLink = cfg.caseURL + event['objectId'] + "/details"
            titleLink = caseLink
        #elif event['objectType'] == "case_task":
        #    objectType = "Task"
        #    titleLink = cfg.caseURL + event['rootId'] + "/tasks/" + event['objectId']
        #elif event['objectType'] == "case_task_log":
        #    objectType = "Task Log"
        #    titleLink = cfg.caseURL + event['rootId'] + "/tasks/" + event['objectId']
        elif event['objectType'] == "alert":
            objectType = "Alert"
            titleLink = cfg.alertsURL
        else:
            return
            #caseId = "none"

        if event['operation'] == "Creation" or event['operation'] == "create":
            operation = "created"
        #elif event['operation'] == "Delete":
        #    operation = "deleted"
        #elif event['operation'] == "Update":
        #    operation = "updated"
        #else:
        #    operation = event['operation']
        else:
            return

        if "description" in event['object']:
            description = event['object']['description'] # create/update
            fields.append(add_object("Description",description,False))
        elif "message" in event['object']:
            description = event['object']['message']
            fields.append(add_object("Description",description,False))
        else:
            description = "none"

        if "status" in event['object']:
            status = event['object']['status']
            fields.append(add_object("Status",status,True))
        else:
            status = "none"

        if "owner" in event['object']:
            owner = event['object']['owner']
            fields.append(add_object("Owner",owner,True))
        else:
            owner = "none"

        if "tlp" in event['object']:
            tlp = event['object']['tlp']
            fields.append(add_object("TLP",tlp,True))
        else:
            tlp = "none"

        if "createdBy" in event['object']:
            createdBy = event['object']['createdBy']
            fields.append(add_object("Created By",createdBy,True))
        else:
            createdBy = "none"

        if "Update" in event['operation']:
            updatedBy = event['object']['updatedBy']
            fields.append(add_object("Updated By",updatedBy,True))
        else:
            updatedBy = owner

        if "updatedAt" in event['object']:
            timestamp = event['object']['updatedAt']
        else:
            timestamp = int(time.time())

        if not titleLink: # if we haven't set it based on object type
            titleLink = cfg.hiveURL

        activity = "TheHive " + str(objectType) + " " + str(operation) + "."

        if "title" in event['object']:
            title = event['object']['title']
        else:
            title = activity

        attachments = {
        ":exclamation:": activity,
        "Owner": (str(updatedBy)),
        "Title": (str(title)),
        "Link": titleLink
        #"color": "danger",
        #"fields": fields,
        #"footer": cfg.orgName,
        #"footer_icon": cfg.orgIcon,
        #"ts": timestamp
        }

        send_to_slack(event,attachments)


def send_to_slack(event,attachments):
    time.sleep(1) # Timeout to avoid HTTP 429, Slack API allows 1 request per second
    slack_message = {
        'username': 'TheHive',
        'icon_emoji': ':honeybee:',
        'channel': cfg.slackChannel,
        'attachments': attachments
    }
    message=slack_message['icon_emoji']+"\n\n"
    for key, value in attachments.items():
        message+=f'{key} : {value}\n\n'

    try:
        req = requests.post(cfg.hookURL, json={"text":message}, proxies=cfg.PROXY_CONFIG, headers={'Content-type': 'application/json'})
        #req = requests.post(cfg.hookURL, json={"text":message}, headers={'Content-type': 'application/json'})
        logger.info("Message posted to %s", slack_message['channel'])
    except Exception as e:
        print("Eeerror")
        print(e)
        logger.error("Something Went wrong: %s", e)

@app.route('/webhookLambda', methods=['POST'])

def lambda_handler():
    hive_event = request.get_json()
    process_event(hive_event)
    return ('Message Sent', 200, None)
