#! /bin/bash

if [ $# -eq 0 ]; then
    echo "No arguments supplied: py <gen|init>"
    exit 1
fi

if [ -d "venv" ]; then
    echo "venv already exists"
    source venv/bin/activate
else
    echo "Creating venv"
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

if [ "$1" == "gen" ]; then
    echo "Generating data.csv"
    python3 scripts/gen.py
elif [ "$1" == "init" ]; then
    echo "Initializing data.db"
    python3 scripts/init.py
else
    echo "Invalid argument: py <gen|init>"
    exit 1
fi
