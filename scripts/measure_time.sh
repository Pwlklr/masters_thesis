#!/bin/bash

# Navigate to root dir to ensure consistent paths
cd "$(dirname "$0")/.." || exit

# Load the Jenkins token from the .env file safely
set -a
source .env
set +a

# Configuration
JENKINS_URL="http://localhost:8080"
USER="admin"
TOKEN="$JENKINS_TOKEN"
RUNS=3

# Generate a unique identifier for this batch of runs
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="results/baseline_run_${TIMESTAMP}.csv"

# The exact names of your Jenkins pipeline jobs
APPS=("PyGoat-Baseline" "django.NV-Baseline" "DVPWA-Baseline" "VAmPI-Baseline")

echo "Starting automated time measurement for $RUNS runs per application..."
echo "Results will be continuously saved to: $RESULT_FILE"

# Initialize CSV header in the results folder
echo "Application,Run_1,Run_2,Run_3,Mean_Time" > "$RESULT_FILE"

for APP in "${APPS[@]}"; do
    echo "====================================================="
    echo "Evaluating Pipeline: $APP"
    
    TOTAL_TIME=0
    RUN_TIMES=()

    for i in $(seq 1 $RUNS); do
        # 1. Identify the next build number
        NEXT_BUILD=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/job/$APP/api/json" | jq -r '.nextBuildNumber')

        echo "  -> Triggering run $i (Build #$NEXT_BUILD)..."
        
        # 2. Trigger the pipeline
        curl -X POST -s -u "$USER:$TOKEN" "$JENKINS_URL/job/$APP/build"

        # 3. Poll safely: wait for the build to leave the queue and finish
        while true; do
            # Use -f to fail silently on 404s (when build is still queued)
            JSON_RESPONSE=$(curl -s -f -u "$USER:$TOKEN" "$JENKINS_URL/job/$APP/$NEXT_BUILD/api/json" 2>/dev/null || echo "")
            
            if [ -n "$JSON_RESPONSE" ]; then
                BUILD_STATUS=$(echo "$JSON_RESPONSE" | jq -r '.building' 2>/dev/null)
                if [ "$BUILD_STATUS" == "false" ]; then
                    break
                fi
            fi
            sleep 3
        done

        # 4. Extract duration
        DURATION_MS=$(echo "$JSON_RESPONSE" | jq -r '.duration')
        DURATION_SEC=$(echo "scale=2; $DURATION_MS / 1000" | bc)
        
        echo "     [Run $i] Completed in $DURATION_SEC seconds."
        TOTAL_TIME=$(echo "$TOTAL_TIME + $DURATION_SEC" | bc)
        RUN_TIMES+=("$DURATION_SEC")
    done

    # 5. Calculate mean and log it
    MEAN_TIME=$(echo "scale=2; $TOTAL_TIME / $RUNS" | bc)
    echo "--> [RESULT] Mean execution time for $APP: $MEAN_TIME seconds"
    echo "====================================================="
    
    # Append the results directly to the CSV
    echo "$APP,${RUN_TIMES[0]},${RUN_TIMES[1]},${RUN_TIMES[2]},$MEAN_TIME" >> "$RESULT_FILE"
done

echo "All runs completed. Data safely indexed in $RESULT_FILE."