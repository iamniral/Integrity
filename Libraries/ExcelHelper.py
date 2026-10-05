import os
import time
import pandas as pd

def read_excel_commands(file_path):
    """Reads the input excel sheet columns."""
    df = pd.read_excel(file_path)
    # Normalize column names to strip trailing/leading spaces
    df.columns = [c.strip() for c in df.columns]
    return df.to_dict(orient='records')

def save_excel_results(source_file_path, results_list):
    """Generates a timestamped result file name and saves the test matrix."""
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    base_name = os.path.basename(source_file_path)
    file_no_ext, ext = os.path.splitext(base_name)
    
    # Force output destination to the '../Output' folder relative to current working directory
    output_dir = os.path.abspath(os.path.join(os.getcwd(), "..", "Output"))
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    result_filename = f"{file_no_ext}_result_{timestamp}{ext}"
    output_path = os.path.join(output_dir, result_filename)
    
    df = pd.DataFrame(results_list)
    # Ensure correct column ordering
    columns_order = ["Action", "Data", "Expected Result", "Actual Result", "Status"]
    # Fallback adjust if user columns are named exactly different
    df = df.reindex(columns=columns_order)
    
    df.to_excel(output_path, index=False)
    return output_path
