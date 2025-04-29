#!/bin/bash

# Check if a name was passed
if [ -z "$1" ]; then
    echo "Usage: ./compile-and-run.sh <filename_without_extension>"
    exit 1
fi

# Compile the Verilog file
iverilog -o a.out "$1.v"

# Only run if compilation succeeded
if [ $? -eq 0 ]; then
    vvp a.out
else
    echo "❌ Compilation failed."
fi
