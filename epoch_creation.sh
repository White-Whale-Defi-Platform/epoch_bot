#!/usr/bin/env bash

project_root_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cd ../ | pwd)

#todo display_usage

function create_epoch() {
    MSG='{"new_epoch":{}}'

    echo "Creating new epoch..."

    local res=$($BINARY tx wasm execute $fee_distributor "$MSG" $TXFLAG --from $bot_address)
    echo $res

    sleep $tx_delay
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
        fee_distributor=$(jq -r --arg chain "$chain" '.[$chain].fee_distributor' $contracts_file)

        # create epoch
        create_epoch

        echo -e "\n ~~~ Epoch creation complete ~~~ \n"
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