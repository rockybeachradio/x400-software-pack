# ~/x400-software-pack/update.py
#!/usr/bin/env python3

################################################################################################
# File: update.py
# Author: Andreas
# Date: 20251125
# Purpose: Is called by Moonraker Update_manager at update process
################################################################################################
# Moonraker’s update_manager has a built-in hook mechanism that automatically executes a file called update.py (if it exists in the root of a git_repo component) every single time an update of that component is triggered from Mainsail/Fluidd.

import os
import subprocess
import sys

REPO_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(REPO_DIR, "scripts", "copy_configs.sh")

print("x400-software-pack: Running copy_configs.sh in AUTO mode...")
print(f"Repo directory : {REPO_DIR}")
print(f"Running script : {SCRIPT}")



if not os.path.isfile(SCRIPT):
    print(f"ERROR: Script not found: {SCRIPT}")
    sys.exit(1)

if not os.access(SCRIPT, os.X_OK):
    print(f"ERROR: Script not executable: {SCRIPT}")
    print("Fix with: chmod +x " + SCRIPT)
    sys.exit(1)

# Run the real update script with AUTO mode
env = {**os.environ, "MOONRAKER_UPDATE": "1"}

result = subprocess.run(
    ["bash", SCRIPT],
    cwd=REPO_DIR,
    env=env
)

if result.returncode != 0:
    print(f"Update failed with exit code {result.returncode}")
    sys.exit(result.returncode)

print("=== x400-software-pack update completed successfully ===")
sys.exit(0)



# Set environment variables so it skips all read -p prompts
result = subprocess.run([
    "bash", SCRIPT
], env={**os.environ, "MOONRAKER_UPDATE": "1"})  # This will be checked inside the script

if result.returncode != 0:
    print(f"Update failed with exit code {result.returncode}")
    sys.exit(result.returncode)

print("x400-software-pack update completed successfully")
sys.exit(0)