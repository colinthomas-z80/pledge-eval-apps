

import re
import sys
import matplotlib.pyplot as plt
from collections import defaultdict

# 2026/09/23 13:58:04.29 vine_manager[416960]vine: Task 2 state change: INITIAL (0) to READY (1)

def parse_log_file(filepath):
    """
    Parse log file and track task state changes.
    Returns lists for timestamps, ready counts, and running counts.
    """
    ready_count = 0
    running_count = 0
    timestamps = []
    state = []
    
    patterns = ["INITIAL (0) to READY (1)", "READY (1) to RUNNING (2)", "RETRIEVED (4) to DONE (5)"]
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                for i, pattern in enumerate(patterns):
                    if pattern in line:
                        parts = line.split()
                        # 2026/09/23 13:58:04.29 vine_manager[416960]vine: Task 2 state change: INITIAL (0) to READY (1)
                        timestamp = parts[1]
                        #hh:mm:ss.ss
                        timestamps.append(timestamp)
                        event_time = timestamp

                        if i == 0:
                            ready_count += 1
                        elif i == 1:
                            ready_count -= 1
                            running_count += 1
                        elif i == 2:
                            running_count -= 1

                        state.append((ready_count, running_count))
                        break
                        
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
    
    return timestamps, [s[0] for s in state], [s[1] for s in state]

def plot_concurrency(filepath):
    """
    Plot the available concurrency: READY and RUNNING task counts over time.
    """
    timestamps, ready_counts, running_counts = parse_log_file(filepath)
    
    if not timestamps:
        print("No valid log entries found.")
        return
    
    plt.figure(figsize=(12, 6))
    plt.plot(range(len(timestamps)), ready_counts, label='READY Tasks', marker='o', linestyle='-', markersize=3)
    plt.plot(range(len(timestamps)), running_counts, label='RUNNING Tasks', marker='s', linestyle='-', markersize=3)
    
    plt.xlabel('Event Index')
    plt.ylabel('Task Count')
    plt.title('Task Concurrency Over Time')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig('concurrency_plot.png', dpi=100)
    plt.show()
    
    print(f"Processed {len(timestamps)} state change events")
    print(f"Final READY count: {ready_counts[-1]}")
    print(f"Final RUNNING count: {running_counts[-1]}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python concurrency_expr_util.py <logfile>")
        sys.exit(1)
    
    plot_concurrency(sys.argv[1])

