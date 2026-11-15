import os
import glob
import pandas as pd
from sqlalchemy import create_engine

# --- CONFIGURATION ---
CSV_FOLDER_PATH = r"FILE PATH"  # Change to your local folder path
DB_USER = "DB_USER"                           # Your pgAdmin username
DB_PASSWORD = "DB_PASSWORD"                   # Your pgAdmin password
DB_HOST = "DB_HOST"
DB_PORT = "DB_PORT"
DB_NAME = "DB_NAME"                # The database you just created

# Connect directly to your new database
engine = create_engine(f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

# Find all CSV files in the folder
csv_files = glob.glob(os.path.join(CSV_FOLDER_PATH, "*.csv"))

if not csv_files:
    print(f"No CSV files found in {CSV_FOLDER_PATH}. Check your folder path!")
else:
    for file_path in csv_files:
        file_name = os.path.basename(file_path)
        # Standardize table name: lowercase, no spaces, no hyphens
        table_name = os.path.splitext(file_name)[0].lower().replace(" ", "_").replace("-", "_")
        
        print(f"Processing '{file_name}'...")
        
        # 1. Read a small sample (1000 rows) to infer data types accurately
        df_sample = pd.read_csv(file_path, nrows=1000)
        
        # Clean column names for PostgreSQL compatibility
        df_sample.columns = [c.lower().replace(" ", "_").replace("-", "_") for c in df_sample.columns]
        
        # 2. Check for timestamp columns in the sample and set them up for auto-parsing
        parse_dates = []
        for col in df_sample.columns:
            if "timestamp" in col or "date" in col:
                parse_dates.append(col)
        
        # 3. Read the full dataframe with date parsing enabled
        df = pd.read_csv(file_path, parse_dates=parse_dates, low_memory=False)
        df.columns = [c.lower().replace(" ", "_").replace("-", "_") for c in df.columns]
        
        print(f"   -> Uploading {len(df)} rows into table '{table_name}'...")
        
        # 4. Stream data directly to PostgreSQL
        # method='multi' pushes chunks rapidly, matching pgAdmin's processing speed
        df.to_sql(table_name, engine, if_exists='replace', index=False, chunksize=10000, method='multi')
        print(f"   -> Successfully created and populated table '{table_name}'.")

    print("\n🎉 All CSV files have been successfully uploaded to your PostgreSQL database!")
    engine.dispose()
