#!/bin/bash

: ${CLOUD_URL:? required}
: ${EMAIL:? required}
: ${PASSWORD:? required}
: ${SSH_KEY_NAME:=seq-master}
: ${REGION:=eu-central-1}
: ${CLUSTER_NAME:? required}
LOG="run.log"

setup() {
  curl -kLo hdc-cli.tgz "${CLOUD_URL}"/hdc-cli_$(uname)_x86_64.tgz
  tar -zxvf hdc-cli.tgz
}

file_checker() {
    HOST=$1

    ssh -o StrictHostKeyChecking=no -i $MASTER_SSH_KEY $CLOUDBREAK_CLOUDBREAK_SSH_USER@$HOST "$(typeset);[[ -e $2 ]]"
}

remove_stuck_cluster() {
  if [[ $(./hdc list-clusters --server "${CLOUD_URL}" --username "${EMAIL}" --password "${PASSWORD}" | jq '.[].ClusterName' | grep $1) ]]; then
    ./hdc --debug terminate-cluster --cluster-name $1 --server "${CLOUD_URL}" --username "${EMAIL}" --password "${PASSWORD}" --wait 1
  fi
}

create_webaccess_template() {
  CLUSTER_TYPES=("BI: Druid 0.9.2 (Technical Preview)" "Data Science: Apache Spark 1.6, Apache Zeppelin 0.6.0" "Data Science: Apache Spark 2.1, Apache Zeppelin 0.6.2" "EDW-Analytics: Apache Hive 2 LLAP, Apache Zeppelin 0.6.0" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 1.6" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 2.0" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 2.1")
  CLUSTER_TYPE="${CLUSTER_TYPES[$3]}"

  cat > cluster-template.json <<EOF
  {
    "ClusterName": "$1",
    "HDPVersion": "$2",
    "ClusterType": "${CLUSTER_TYPE}",
    "Master": {
        "InstanceType": "m4.4xlarge",
        "VolumeType": "gp2",
        "VolumeSize": 32,
        "VolumeCount": 1,
        "RecoveryMode": "MANUAL",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "Worker": {
        "InstanceType": "m3.xlarge",
        "VolumeType": "ephemeral",
        "VolumeSize": 40,
        "VolumeCount": 2,
        "InstanceCount": 3,
        "RecoveryMode": "AUTO",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "Compute": {
        "InstanceType": "m3.xlarge",
        "VolumeType": "ephemeral",
        "VolumeSize": 40,
        "VolumeCount": 2,
        "InstanceCount": 1,
        "RecoveryMode": "MANUAL",
        "SpotPrice": "0.8",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "SSHKeyName": "${SSH_KEY_NAME}",
    "RemoteAccess": "0.0.0.0/0",
    "WebAccess": true,
    "WebAccessHive": true,
    "WebAccessClusterManagement": false,
    "ClusterAndAmbariUser": "admin",
    "ClusterAndAmbariPassword": "Admin123!@#\"",
    "Tags": {
        "kisnyul": "pityuka",
	      "+-=. _:/@": "+-=. _:/@"
    },
    "InstanceRole": "CREATE"
  }
EOF
}

create_nowebaccess_template() {
  CLUSTER_TYPES=("BI: Druid 0.9.2 (Technical Preview)" "Data Science: Apache Spark 1.6, Apache Zeppelin 0.6.0" "Data Science: Apache Spark 2.1, Apache Zeppelin 0.6.2" "EDW-Analytics: Apache Hive 2 LLAP, Apache Zeppelin 0.6.0" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 1.6" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 2.0" "EDW-ETL: Apache Hive 1.2.1, Apache Spark 2.1")
  CLUSTER_TYPE="${CLUSTER_TYPES[$3]}"

  cat > cluster-template.json <<EOF
  {
    "ClusterName": "$1",
    "HDPVersion": "$2",
    "ClusterType": "${CLUSTER_TYPE}",
    "Master": {
        "InstanceType": "m4.4xlarge",
        "VolumeType": "gp2",
        "VolumeSize": 32,
        "VolumeCount": 1,
        "RecoveryMode": "MANUAL",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "Worker": {
        "InstanceType": "m3.xlarge",
        "VolumeType": "ephemeral",
        "VolumeSize": 40,
        "VolumeCount": 2,
        "InstanceCount": 3,
        "RecoveryMode": "AUTO",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "Compute": {
        "InstanceType": "m3.xlarge",
        "VolumeType": "ephemeral",
        "VolumeSize": 40,
        "VolumeCount": 2,
        "InstanceCount": 1,
        "RecoveryMode": "MANUAL",
        "SpotPrice": "0.8",
        "Recipes": [
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/a31408e3110eee0ffa34d29db25519d4/raw/be9fc7198d64a9a98ce319a867a6c5e6270386b4/pre-install.sh",
                "Phase": "pre"
            },
            {
                "URI": "https://gist.githubusercontent.com/aszegedi/4fc4a6a2fd319da436df6441c04c68e1/raw/5698a1106a2365eb543e9d3c830e14f955882437/post-install.sh",
                "Phase": "post"
            }
        ]
    },
    "SSHKeyName": "${SSH_KEY_NAME}",
    "RemoteAccess": "0.0.0.0/0",
    "WebAccess": false,
    "WebAccessHive": false,
    "WebAccessClusterManagement": false,
    "ClusterAndAmbariUser": "admin",
    "ClusterAndAmbariPassword": "Admin123!@#\"",
    "Tags": {
        "kisnyul": "pityuka",
	      "+-=. _:/@": "+-=. _:/@"
    },
    "InstanceRole": "CREATE"
  }
EOF
}

#teardown() {
#  rm -f hdc hdc-cli.tgz cluster-template.json
#}
