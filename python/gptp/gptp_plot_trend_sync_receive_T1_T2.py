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
    match_count = 0  # To keep track of how many matches we have seen
    
    # Regex to match T1, T2, T3 values in the log line
    pattern = r"T1:\s*(\d+)\s*T2:\s*(\d+)\s*T2-T1:\s*(\d+)"
    
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
                    
                    # Store the T1, T2, T3, and T4 values
                    t1_values.append(T1)
                    t2_values.append(T2)
                    t3_values.append(T3)
    
    return t1_values, t2_values, t3_values

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
def plot_data(t1_values, t2_values, t3_values):
    # Generate x-axis values (row numbers starting from 1)
    x = range(1, len(t1_values) + 1)
    
    fig, ax1 = plt.subplots()

    # Plot T1 and T2 on the primary y-axis
    ax1.plot(x, t1_values, label="T1 Inc", color="blue")
    ax1.plot(x, t2_values, label="T2 Inc", color="green")
    ax1.set_xlabel('Row Number')
    ax1.set_ylabel('T1 and T2 Inc', color='black')
    ax1.tick_params(axis='y', labelcolor='black')

    # Create a secondary y-axis for T3
    ax2 = ax1.twinx()
    ax2.plot(x, t3_values, label="T2-T1", color="red")
    ax2.set_ylabel('T2-T1 Values', color='red')
    ax2.tick_params(axis='y', labelcolor='red')

    # Add title and legends
    plt.title('T1, T2, and T2-T1 Values Over Rows (Skipping First 60 Matches)')
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
    t1_values, t2_values, t3_values = extract_data(file_path)
    
    # Step 3: Check if we got any data
    if not t1_values or not t2_values or not t3_values:
        print("No matching data found in the file.")
        return
    
    # Step 4: Compute the differences between consecutive elements
    t1_values = compute_differences(t1_values)
    t2_values = compute_differences(t2_values)
    t3_values = t3_values[0:len(t1_values)]
    
    # Filter out values that are more than 900000000
    #t1_values = [value for value in t1_values if value < 900000000]
    #t2_values = [value for value in t2_values if value < 900000000]
    #t3_values = [value for value in t3_values if value < 900000000]

    # Step 5: Plot the data
    plot_data(t1_values, t2_values, t3_values)

if __name__ == "__main__":
    main()