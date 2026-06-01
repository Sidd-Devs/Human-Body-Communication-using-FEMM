# -*- coding: utf-8 -*-
"""
Original file is located at
    https://colab.research.google.com/drive/1TfTCX2zGq3_YCbSPA4Kjj4oUo9no5brm
"""

import matplotlib.pyplot as plt
import matplotlib as mpl

plt.style.use('seaborn-v0_8-colorblind')  # IEEE-friendly colorblind-safe style

# Define a color map for IEEE style (colorblind-friendly)
ieee_colors = mpl.colormaps['tab10'].colors  # tab10 is widely accepted for publications

# Datasets
import pandas as pd

# Read data from results.csv
df = pd.read_csv('results.csv')

# Debugging: Print the columns in the CSV file
print('CSV columns:', df.columns.tolist())

# Extract sweep data for each parameter

def get_sweep_data(param):
    sweep = df[df['SweepParam'] == param]
    x = sweep[param].dropna().tolist()
    y = sweep['Rx_Voltage'].dropna().tolist()
    y_mV = [v * 1000 for v in y]
    return x, y_mV

TxD, TxD_Rx_Voltage_mV = get_sweep_data('TxD')
TxW, TxW_Rx_Voltage_mV = get_sweep_data('TxW')
TxG, TxG_Rx_Voltage_mV = get_sweep_data('TxG')
RxH, RxH_Rx_Voltage_mV = get_sweep_data('RxH')
RxA, RxA_Rx_Voltage_mV = get_sweep_data('RxA')

RxA = [abs(x) for x in RxA]  # Make RxA positive for plotting



# --- Combined Figure with Subplots in a Single Row ---
fig, axes = plt.subplots(1, 5, figsize=(25, 5))
fig.tight_layout(pad=4.0)  # Add tight layout for better spacing

subplot_labels = ['a)', 'b)', 'c)', 'd)', 'e)']
plot_colors = [ieee_colors[0], ieee_colors[1], ieee_colors[2], ieee_colors[3], ieee_colors[4]]

for ax, label in zip(axes, subplot_labels):
    ax.text(-0.15, 1.08, label, transform=ax.transAxes, fontsize=16, va='top', ha='right')
    ax.tick_params(axis='both', which='major', labelsize=14)  # Set tick label fontsize to 14

axes[0].plot(TxD, TxD_Rx_Voltage_mV, marker='o', linestyle='-', linewidth=2, color=plot_colors[0])
axes[0].set_xlabel('TxD (cm)', fontsize=16)
axes[0].set_ylabel(r'$V_{\mathrm{Rx}}$ (mV)', fontsize=16)
axes[0].grid(True)

axes[1].plot(TxW, TxW_Rx_Voltage_mV, marker='s', linestyle='-', linewidth=2, color=plot_colors[1])
axes[1].set_xlabel('TxW (cm)', fontsize=16)
axes[1].set_ylabel(r'$V_{\mathrm{Rx}}$ (mV)', fontsize=16)
axes[1].grid(True)

axes[2].plot(TxG, TxG_Rx_Voltage_mV, marker='^', linestyle='-', linewidth=2, color=plot_colors[2])
axes[2].set_xlabel('TxG (cm)', fontsize=16)
axes[2].set_ylabel(r'$V_{\mathrm{Rx}}$ (mV)', fontsize=16)
axes[2].grid(True)

axes[3].plot(RxH, RxH_Rx_Voltage_mV, marker='D', linestyle='-', linewidth=2, color=plot_colors[3])
axes[3].set_xlabel('RxH (cm)', fontsize=16)
axes[3].set_ylabel(r'$V_{\mathrm{Rx}}$ (mV)', fontsize=16)
axes[3].grid(True)

axes[4].plot(RxA, RxA_Rx_Voltage_mV, marker='v', linestyle='-', linewidth=2, color=plot_colors[4])
axes[4].set_xlabel('RxA (cm)', fontsize=16)
axes[4].set_ylabel(r'$V_{\mathrm{Rx}}$ (mV)', fontsize=16)
axes[4].grid(True)


fig.tight_layout(pad=4.0)
plt.savefig('Combined.png', dpi=600)
plt.show()

