# WW Epoch bot

This project contains a series of scripts to keep epochs up-to-date on White Whale's liquidity hubs.

## How it works

There's a main script called `epoch_bot.py` that invokes additional scripts done in bash. The `epoch_bot.py` 
works as a glue between all the other scripts, and makes sure they are run on schedule.

The `env` folder contains everything related to the environmental variables, chain details and so on.

`/env/contracts.json` contains information about the necessary contracts in each chain to keep the epochs up to date. 
The process involves collecting and aggregating fees (randomly, to avoid frontrunning), and making sure epochs
are created if they are lagging behind.

The bot wallet can be configured in `wallet_importer.sh`.

Additionally, the bot has a heartbeat and notifications via Slack. Notifications include: successful and unsuccessful execution, low balance in bot address.

## Setup

- Install python 3 and pip
- Install pip schedule, requests and all other additional python package in the script.
- Install the cli tools for each chain, i.e. `migalood`, `terrad`, `osmosisd` etc and make sure they are accessible on your `$PATH`.
- Add two env variables to your `$PATH`:
    - `DAEMON_PASSWORD` which includes the password for the cli tool
    - `SLACK_WEBHOOK_URL` which is the webhook url for your slack application.

## Running the bot

You can run the python script in the background with `nohub python epoch_bot.py &`. 
 