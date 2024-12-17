#!/usr/bin/env bash
#set -e

project_root_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cd ../ | pwd)

# Initializes chain env variables
function init_chain_env() {
	if [ $# -eq 1 ]; then
		local chain=$1
	else
		echo "init_chain_env requires a chain"
		exit 1
	fi

	source <(cat "$project_root_path"/env/deploy_env/mainnets/"$chain".env)

	# load the base env, i.e. the TXFLAG
	source "$project_root_path"/env/deploy_env/base_env.sh $chain
}
