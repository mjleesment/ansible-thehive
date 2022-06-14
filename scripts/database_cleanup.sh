#!/bin/bash

find . -type f | grep `date --date='-2 month' +backup_%Y%m` | xargs rm
