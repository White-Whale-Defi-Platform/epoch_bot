import schedule
import time
import random
import subprocess
import json
from slack_dispatcher import send_slack_notification

# Load the chains.json file and extract chain names
def load_chains():
    with open('env/contracts.json') as f:
        chains_data = json.load(f)
    chain_names = list(chains_data.keys())
    return chain_names

# Load the min_balance.json file
def load_min_balance():
    with open('env/min_balance.json') as f:
        return json.load(f)

def run_script(script_name, chain):
    print(f"Running {script_name} with chain: {chain}")
    result = subprocess.run(['bash', script_name, '-c', chain], capture_output=True, text=True)
    if result.returncode == 0:
        print(f"{script_name} completed successfully for chain: {chain}")
        send_slack_notification(f"Success: {script_name} completed successfully for chain: {chain}")
    else:
        print(f"{script_name} failed for chain: {chain}. Error: {result.stderr}")
        send_slack_notification(f"Error: {script_name} failed for chain: {chain}. Error: {result.stderr}")
    return result.stdout.strip()

def check_balance(chain, min_balance):
    balance = run_script('check_bot_balance.sh', chain)
    print(f"Balance for {chain}: {balance}")

    if chain in min_balance:
        min_balance_value = min_balance[chain]
        if int(balance) < min_balance_value:
            message = f"Alert: Balance for {chain} is below minimum ({balance} < {min_balance_value})"
            send_slack_notification(message)
        else:
            print(f"Balance for {chain} is sufficient ({balance} >= {min_balance_value})")
    else:
        print(f"No minimum balance specified for {chain}")

def run_fee_aggregation(chains, min_balance):
    for chain in chains:
        output = run_script('fee_aggregation.sh', chain)
        print(f"Output from fee_aggregation.sh: {output}")

        # Check balance after fee aggregation for each chain
        check_balance(chain, min_balance)

def run_epoch_creation(chains, min_balance):
    for chain in chains:
        output = run_script('epoch_creation.sh', chain)
        print(f"Output from epoch_creation.sh: {output}")

        # Check balance after epoch creation for each chain
        check_balance(chain, min_balance)

def run_incentives_snapshot(chains, min_balance):
    for chain in chains:
        output = run_script('incentives_snapshot.sh', chain)
        print(f"Output from incentives_snapshot.sh: {output}")

        # Check balance after incentives snapshot for each chain
        check_balance(chain, min_balance)

def run_random_fee_aggregation(chains, min_balance):
    current_hour = time.localtime().tm_hour
    current_minute = time.localtime().tm_min
    current_time = current_hour * 60 + current_minute
    start_time = 13 * 60  # 13:00 UTC in minutes
    end_time = 14 * 60 + 40  # 14:40 UTC in minutes

    if current_time < start_time:
        # Calculate the random delay within the window
        min_delay = (start_time - current_time) * 60  # in seconds
        max_delay = (end_time - current_time) * 60  # in seconds
        random_delay = random.randint(min_delay, max_delay)
        time_to_run = time.time() + random_delay

        print(f"Scheduling fee_aggregation.sh to run in {random_delay // 60} minutes and {(random_delay % 60)} seconds...")
        schedule.run_pending()
        time.sleep(random_delay)
        run_fee_aggregation(chains, min_balance)
    elif current_time >= start_time and current_time < end_time:
        # Current time is within the window, run it immediately
        print("Current time is within the window. Running fee_aggregation.sh immediately...")
        run_fee_aggregation(chains, min_balance)
    else:
        print("Current time is after 14:40 UTC. Skipping fee_aggregation.sh for today.")

def heartbeat():
    message = "Heartbeat: Scheduler is running and all tasks are scheduled."
    send_slack_notification(message)
    print(message)

def main():
    chains = load_chains()
    print(f"Loaded chain names: {chains}")
    
    min_balance = load_min_balance()
    # Schedule epoch_creation.sh and incentives_snapshot.sh to run at 17:00 UTC
    schedule.every().day.at("17:00").do(run_epoch_creation, chains, min_balance)
    schedule.every().day.at("17:01").do(run_incentives_snapshot, chains, min_balance)
    # Schedule heartbeat to run at midnight UTC
    schedule.every().day.at("00:00").do(heartbeat)

    while True:
        run_random_fee_aggregation(chains, min_balance)
        schedule.run_pending()
        time.sleep(60)  # Check every minute

if __name__ == "__main__":
    main()