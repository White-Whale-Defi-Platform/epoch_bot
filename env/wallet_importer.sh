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

	bot_wallet='epoch_bot'
	bot_address=$($BINARY keys show $bot_wallet --output json | jq -r '.address')
}
