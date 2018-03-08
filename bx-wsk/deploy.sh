#!/bin/bash

##############################################################################
# Copyright 2017-2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

# Load configuration variables
source ../local.env

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
  set -e

  echo -e "Installing actions, triggers, and rules for ibm-cloud-functions-refarch-data-processing-message-hub..."

  echo -e "Make IBM Message Hub connection info available to IBM Cloud Functions"
  bx wsk package refresh

  echo "Creating the message-trigger trigger"
  bx wsk trigger create message-trigger \
    --feed Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubFeed \
    --param isJSONData true \
    --param topic ${SRC_TOPIC}

  echo "Creating the package for the actions"
  bx wsk package create data-processing-message-hub

  echo "Creating receive-consume action as a Node.js action"
  bx wsk action create data-processing-message-hub/receive-consume ../runtimes/nodejs/actions/receive-consume.js

  echo "Creating transform-produce action as a Node.js action"
  bx wsk action create data-processing-message-hub/transform-produce ../runtimes/nodejs/actions/transform-produce.js \
    --param topic ${DEST_TOPIC} \
    --param kafka ${KAFKA_INSTANCE}

  echo "Creating the message-processing-sequence sequence that links the consumer and producer actions"
  bx wsk action create data-processing-message-hub/message-processing-sequence --sequence data-processing-message-hub/receive-consume,data-processing-message-hub/transform-produce

  echo "Creating the  message-rule rule that links the trigger to the sequence"
  bx wsk rule create message-rule message-trigger message-processing-sequence

  echo -e "Install Complete"
}


function uninstall() {
  echo -e "Uninstalling..."

  bx wsk rule delete --disable message-rule
	bx wsk trigger delete message-trigger
	bx wsk action delete data-processing-message-hub/message-processing-sequence
	bx wsk action delete data-processing-message-hub/receive-consume
	bx wsk action delete data-processing-message-hub/transform-produce
  bx wsk package delete Bluemix_${KAFKA_INSTANCE}_Credentials-1
  bx wsk package delete data-processing-message-hub

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e KAFKA_INSTANCE="$KAFKA_INSTANCE"
  echo -e SRC_TOPIC="$SRC_TOPIC"
  echo -e DEST_TOPIC="$DEST_TOPIC"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--env" )
showenv
;;
* )
usage
;;
esac
