import pandas as pd
import sys 
import json
import os

def load_data(fname):
    if not os.path.exists(fname):
        raise FileNotFoundError(f"File not found: {fname}")
    return json.load(open(fname))

def column_names(data):
    cols = ["timestamp"]
    cols.extend(data["rates"].keys())
    return cols

def values(data):
    values = [data["timestamp"]]
    values.extend(data["rates"].values())
    return values

if __name__ == "__main__":
    fname = "data/example.json"
    if len(sys.argv) > 2:
        fname = sys.argv[1]

    data = load_data(fname)

    df = pd.DataFrame(columns=column_names(data))
    df.loc[0] = values(data)
    
    assert df.shape[1] == len(data["rates"]) + 1
    df.to_csv("data/data.csv", index=False)


    