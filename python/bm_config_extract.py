"""
Module Name: bm_config_extract.py
Author: Leipo Yan

License: This work is licensed under a Creative Commons Attribution-NonCommercial
4.0 International License.
For more information, visit https://creativecommons.org/licenses/by-nc/4.0/
"""

import tkinter as tk
from tkinter import filedialog
from bm_config import BMConfig, BMConfigDTSIWriter

def select_file():
    """Pop up a file dialog to select the Excel file"""
    tk.Tk().withdraw()
    file_path = filedialog.askopenfilename(
    	filetypes=[('Excel files', '*.xlsx'), ('All files', '*.*')]
    )
    return file_path

def main():
    file_path = select_file()

    if file_path:
        print(f"Selected file: {file_path}")
        
        # Extract BM configurations from the Excel file
        bm_config = BMConfig(file_path)
        bm_config_writer = BMConfigDTSIWriter(bm_config)
        bm_config_writer.write_dtsi()

if __name__ == "__main__":
    main()

