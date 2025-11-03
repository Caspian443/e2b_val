#!/bin/bash
# This script is meant to be run in the Startup Script of each Compute Instance while it's booting. The script uses the
# run-nomad and run-consul scripts to configure and start Consul and Nomad in server mode. Note that this script
# assumes it's running in a Google IMage built from the Packer template in examples/nomad-consul-image/nomad-consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# Inspired by https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

ulimit -n 65536
export GOMAXPROCS='nproc'

#gsutil cp "gs://${SCRIPTS_BUCKET}/run-consul-${RUN_CONSUL_FILE_HASH}.sh" /opt/consul/bin/run-consul.sh
#gsutil cp "gs://${SCRIPTS_BUCKET}/run-nomad-${RUN_NOMAD_FILE_HASH}.sh" /opt/nomad/bin/run-nomad.sh

#chmod +x /opt/consul/bin/run-consul.sh /opt/nomad/bin/run-nomad.sh

/opt/consul/bin/run-consul.sh --server --cluster-tag-name "e2b-north" --consul-token "d0ba2421-2e78-a365-13d7-14110c2e1990" --enable-gossip-encryption --gossip-encryption-key "KnlmMBBQ1UQe2gGDCj2DtJ2X9ZkIxjuj7VhAlE8EzHk="
/opt/nomad/bin/run-nomad.sh --server --num-servers "1" --consul-token "d0ba2421-2e78-a365-13d7-14110c2e1990" --nomad-token "79fd6fb2-ef94-7b05-8eb3-7cabf872c90f"

