# Project Setup Guide

Note - You need to install FEMM tool from https://www.femm.info/wiki/pyFEMM#
This project is compatible with **Python 3.10.11**. 
FEMM software version 4.2, Windows 11

## Usage (After Initialization)
.\venv\Scripts\Activate

## Setting Up the Virtual Environment (for the first time)
python -m venv venv
.\venv\Scripts\Activate
pip install -r requirements.txt

## Manuscript Resultscd

Demonstration of FEMM Simulation: Conference-Demo/sim-hbc.py
1. $cd Conference-Demo; $python sim-hbc.py
2. Open FEMM software, next open hbc.res from the folder to view the result

Channel Characteristics vs. Model Parameters: 
    Run: $cd Conference-Exp; python sim-hbc.py
    Then, run: plot-combined.py