#!/usr/bin/env bash

project_root_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cd ../ | pwd)

#todo display_usage


function collect_fees() {
    local is_pool="$1"
    if [[ -z "$is_pool" ]]; then
        echo "Error: Value must be provided"
        return 1
    elif [[ "$is_pool" -eq 0 ]]; then
        MSG='{"collect_fees":{"collect_fees_for":{"factory":{"factory_addr":"'$vault_factory'","factory_type":{"vault":{}}}}}}'
    elif [[ "$is_pool" -eq 1 ]]; then
        MSG='{"collect_fees":{"collect_fees_for":{"factory":{"factory_addr":"'$pool_factory'","factory_type":{"pool":{}}}}}}'
    else
        echo "Error: Value must be 0 or 1, for vaults or pools respectively"
        return 1
    fi

    echo "Collecting fees..."

    local res=$($BINARY tx wasm execute $fee_collector "$MSG" $TXFLAG --from $bot_address)
    echo $res

    sleep $tx_delay
}

function aggregate_fees() {
    local is_pool="$1"
    if [[ -z "$is_pool" ]]; then
        echo "Error: Value must be provided"
        return 1
    elif [[ "$is_pool" -eq 0 ]]; then
        MSG='{"aggregate_fees":{"aggregate_fees_for":{"factory":{"factory_addr":"'$vault_factory'","factory_type":{"vault":{}}}}}}'
    elif [[ "$is_pool" -eq 1 ]]; then
        MSG='{"aggregate_fees":{"aggregate_fees_for":{"factory":{"factory_addr":"'$pool_factory'","factory_type":{"pool":{}}}}}}'
    else
        echo "Error: Value must be 0 or 1, for vaults or pools respectively"
        return 1
    fi

    echo "Aggregating fees..."

    local res=$($BINARY tx wasm execute $fee_collector "$MSG" $TXFLAG --from $bot_address)
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
        fee_collector=$(jq -r --arg chain "$chain" '.[$chain].fee_collector' $contracts_file)
        pool_factory=$(jq -r --arg chain "$chain" '.[$chain].pool_factory' $contracts_file)
        vault_factory=$(jq -r --arg chain "$chain" '.[$chain].vault_factory' $contracts_file)

        # collect fees for both vaults and pools
        collect_fees 0
        collect_fees 1

        # aggregate fees for both vaults and pools
        aggregate_fees 0
        aggregate_fees 1

        echo -e "\n ~~~ Fee aggregation complete ~~~ \n"
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