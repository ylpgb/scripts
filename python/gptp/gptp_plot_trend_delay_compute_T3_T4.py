import tkinter as tk
from tkinter import filedialog
import re
import matplotlib.pyplot as plt

# Function to prompt the user to select a file
def select_file():
    root = tk.Tk()
    root.withdraw()  # Hide the main tkinter window
    file_path = filedialog.askopenfilename(title="Select the log file", filetypes=(("Log files", "*.log"), ("All files", "*.*")))
    return file_path

# Function to parse the file and extract the T1, T2, T3, and T4 values (skip the first 60 matches)
def extract_data(file_path):
    t1_values = []
    t2_values = []
    t3_values = []
    t4_values = []
    t2_t1_values = []
    t4_t3_values = []
    match_count = 0  # To keep track of how many matches we have seen
    
    # Regex to match T1, T2, T3, T4, T2-T1, T4-T3 values in the log line
    pattern = r'T1:\s*(\d+),\s*T2:\s*(\d+),\s*T3:\s*(\d+),\s*T4:\s*(\d+)\s*T2-T1:\s*(\d+)\s*T4-T3:\s*(\d+)'
    
    with open(file_path, 'r') as file:
        for line in file:
            match = re.search(pattern, line)
            if match:
                match_count += 1
                # Skip the first 60 matches
                if match_count > 60:
                    T1 = int(match.group(1))
                    T2 = int(match.group(2))
                    T3 = int(match.group(3))
                    T4 = int(match.group(4))
                    T2_T1 = int(match.group(5))
                    T4_T3 = int(match.group(6))
                    
                    # Store the T1, T2, T3, and T4 values
                    t1_values.append(T1)
                    t2_values.append(T2)
                    t3_values.append(T3)
                    t4_values.append(T4)
                    t2_t1_values.append(T2_T1)
                    t4_t3_values.append(T4_T3)
    
    return t1_values, t2_values, t3_values, t4_values, t2_t1_values, t4_t3_values

# Function to compute the differences between consecutive elements in a list
def compute_differences(values):
    differences = []
    for i in range(1, len(values)):
        diff = values[i] - values[i - 1]
        #offset = round(diff / 1000000000) * 1000000000
        offset = 1000000000

        if abs(diff - offset) > 1000000:
            print(f"Large difference detected: values[{i}] = {values[i]}, values[{i - 1}] = {values[i - 1]}, diff = {diff}, offset = {offset}")    
        differences.append(diff - offset)
    return differences

# Function to plot the data
def plot_data(t3_values, t4_values, t4_t3_values):
    # Generate x-axis values (row numbers starting from 1)
    x = range(1, len(t3_values) + 1)
    
    fig, ax1 = plt.subplots()

    # Plot T1 and T2 on the primary y-axis
    ax1.plot(x, t3_values, label="T3 Inc", color="blue")
    ax1.plot(x, t4_values, label="T4 Inc", color="green")
    ax1.set_xlabel('Row Number')
    ax1.set_ylabel('T3 and T4 Inc', color='black')
    ax1.tick_params(axis='y', labelcolor='black')

    # Create a secondary y-axis for T3
    ax2 = ax1.twinx()
    ax2.plot(x, t4_t3_values, label="T4-T3", color="red")
    ax2.set_ylabel('T4-T3 Values', color='red')
    ax2.tick_params(axis='y', labelcolor='red')

    # Add title and legends
    plt.title('T3, T4, and T4-T3 Values Over Rows (Skipping First 60 Matches)')
    fig.tight_layout()  # Adjust layout to prevent overlap

    # Add legends
    ax1.legend(loc='upper left')
    ax2.legend(loc='upper right')
    
    # Show the plot
    plt.show()

def main():
    # Step 1: Prompt the user to select a file
    file_path = select_file()
    if not file_path:
        print("No file selected. Exiting...")
        return
    
    # Step 2: Extract the data, skipping the first 60 matches
    t1_values, t2_values, t3_values, t4_values, t2_t1_values, t4_t3_values = extract_data(file_path)
    
    # Step 3: Check if we got any data
    if not t3_values or not t4_values or not t4_t3_values:
        print("No matching data found in the file.")
        return
    
    # Step 4: Compute the differences between consecutive elements
    t3_values = compute_differences(t3_values)
    t4_values = compute_differences(t4_values)
    t4_t3_values = t4_t3_values[0:len(t4_t3_values)-1]

    print(f"t3_len: {len(t3_values)}, t4_len: {len(t4_values)}, t4_t3_len: {len(t4_t3_values)}")
    # Step 5: Plot the data
    plot_data(t3_values, t4_values, t4_t3_values)

if __name__ == "__main__":
    main()