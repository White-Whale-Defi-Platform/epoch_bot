#!/usr/bin/env bash

project_root_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cd ../ | pwd)

#todo display_usage

function take_incentive_snapshots() {
	if [ -n "$1" ]; then
		local lp_asset=$1
		local query='{"incentives":{"limit":30, "start_after": '$lp_asset'}}'
	else
		local query='{"incentives":{"limit":30}}'
	fi

	local res=($($BINARY query wasm contract-state smart $incentive_factory "$query" --output json --node $RPC | jq -r '.data[] | .incentive_address'))

	incentive_counter=0

	for incentive in "${res[@]}"
	do
		echo "Taking snapshot for incentive $incentive..."

		#take snapshot
		MSG='{"take_global_weight_snapshot":{}}'

	  	local res=$($BINARY tx wasm execute $incentive "$MSG" $TXFLAG --from $bot_address)
    	echo $res
		sleep $tx_delay

		incentive_counter=$((incentive_counter+1))

		# if over 30 values, paginate
		if [ $incentive_counter -ge 30 ]; then
			echo "Paginating incentives..."
			local query='{"config":{}}'
			local lp_asset=$($BINARY query wasm contract-state smart $incentive "$query" --output json --node $RPC | jq '.data.lp_asset')
			take_incentive_snapshots "$lp_asset"
		fi
	done
}

# get args
optstring=':c:h'
while getopts $optstring arg; do
	source $project_root_path/env/wallet_importer.sh

	case "$arg" in
	c)
		chain=$OPTARG
		source $project_root_path/env/deploy_env/chain_env.sh
		init_chain_env $OPTARG
		tx_delay=8
        import_bot_wallet $chain

        contracts_file=$project_root_path/env/contracts.json

        # Load contracts
        incentive_factory=$(jq -r --arg chain "$chain" '.[$chain].incentive_factory' $contracts_file)

        # create epoch
        take_incentive_snapshots

        echo -e "\n ~~~ Incentive snapshots complete ~~~ \n"
		;;
	h)
		display_usage
		exit 0
		;;
	:)
		echo "Must supply an argument to -$OPTARG" >&2
		exit 1
		;;
	?)
		echo "Invalid option: -${OPTARG}"
		display_usage
		exit 2
		;;
	esac
done