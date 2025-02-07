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

# Function to parse the file and extract the T2-T1 and T4-T3 values (skip the first 60 matches)
def extract_data(file_path):
    t2_t1_values = []
    t4_t3_values = []
    match_count = 0  # To keep track of how many matches we have seen
    
    # Regex to match T1, T2, T3, and T4 values in the log line
    pattern = r'T1:\s*(\d+),\s*T2:\s*(\d+),\s*T3:\s*(\d+),\s*T4:\s*(\d+)'
    
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
                    
                    # Compute the differences T2-T1 and T4-T3
                    t2_t1_values.append(T2 - T1)
                    t4_t3_values.append(T4 - T3)
    
    return t2_t1_values, t4_t3_values

# Function to plot the data
def plot_data(t2_t1_values, t4_t3_values):
    # Generate x-axis values (row numbers starting from 61)
    x = range(1, len(t2_t1_values) + 1)
    
    # Create the plot
    plt.plot(x, t2_t1_values, label="T2-T1", color="blue")
    plt.plot(x, t4_t3_values, label="T4-T3", color="red")
    
    # Add labels and title
    plt.xlabel('Row Number')
    plt.ylabel('Value')
    plt.title('T2-T1 and T4-T3 Values Over Rows (Skipping First 60 Matches)')
    
    # Add legend
    plt.legend()
    
    # Show the plot
    plt.show()

def main():
    # Step 1: Prompt the user to select a file
    file_path = select_file()
    if not file_path:
        print("No file selected. Exiting...")
        return
    
    # Step 2: Extract the data, skipping the first 60 matches
    t2_t1_values, t4_t3_values = extract_data(file_path)
    
    # Step 3: Check if we got any data
    if not t2_t1_values or not t4_t3_values:
        print("No matching data found in the file.")
        return
    
    # Step 4: Plot the data
    plot_data(t2_t1_values, t4_t3_values)

if __name__ == "__main__":
    main()
