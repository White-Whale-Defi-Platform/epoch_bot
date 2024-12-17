#!/usr/bin/env bash
set -e

project_root_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cd ../ | pwd)

# Imports the bot wallet
function import_bot_wallet() {
	if [ $# -eq 1 ]; then
		local chain=$1
	else
		echo "import_bot_wallet requires a chain to load the right mnemonic"
		exit 1
	fi

	bot_wallet='bot_wallet'
	local mnemonic=$(cat "$project_root_path"/scripts/deployment/deploy_env/mnemonics/bot_mnemonic.txt)

	# verify if the bot_wallet wallet has already been imported
	if ! $BINARY keys show $bot_wallet >/dev/null 2>&1; then
		# wallet needs to be imported
		echo "Importing $bot_wallet into $BINARY..."
		echo $mnemonic | $BINARY keys add $bot_wallet --recover >/dev/null 2>&1
	fi

	bot_address=$($BINARY keys show $bot_wallet --output json | jq -r '.address')
}
