import os

hookURL = os.environ['hookURL']
slackChannel = os.environ['slackChannel']
orgName = os.environ['orgName']
orgIcon = os.environ['orgIcon']
hiveURL = os.environ['hiveURL']
caseURL = hiveURL + "/index.html#!/case/"
alertsURL = hiveURL + "/index.html#!/alert/list"

PROXY_CONFIG = {
  "http": os.environ['httpProxy'],
  "https": os.environ['httpsProxy']
}
