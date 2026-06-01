# -*- coding: utf-8 -*-
"""
Original file is located at
    https://colab.research.google.com/drive/1TfTCX2zGq3_YCbSPA4Kjj4oUo9no5brm
"""

import matplotlib.pyplot as plt

plt.style.use('ggplot')

# Datasets
TxD = [10, 15, 20, 25, 30, 35, 40]
TxD_Rx_Voltage = [0.094005, 0.117468, 0.136607, 0.153958, 0.16967, 0.18554, 0.201655]

TxW = list(range(1, 11))
TxW_Rx_Voltage = [0.142722, 0.139555, 0.136607, 0.134599, 0.133721, 0.133074, 0.132881, 0.133466, 0.134629, 0.135756]

TxG = list(range(1, 11))
TxG_Rx_Voltage = [0.138753, 0.137375, 0.136607, 0.135291, 0.135095, 0.134719, 0.134493, 0.134337, 0.134406, 0.134297]

RxH = [10, 20, 30, 40, 50]
RxH_Rx_Voltage = [0.090542, 0.115447, 0.136607, 0.155835, 0.174036]

# Convert all Rx Voltage data from V to mV
TxD_Rx_Voltage_mV = [v * 1000 for v in TxD_Rx_Voltage]
TxW_Rx_Voltage_mV = [v * 1000 for v in TxW_Rx_Voltage]
TxG_Rx_Voltage_mV = [v * 1000 for v in TxG_Rx_Voltage]
RxH_Rx_Voltage_mV = [v * 1000 for v in RxH_Rx_Voltage]
RxA = [5, 10, 15, 20, 25, 30, 35, 40]
RxA_Rx_Voltage = [0.098239, 0.136607, 0.171256, 0.202381, 0.23101, 0.257882, 0.283219, 0.307205]
RxA_Rx_Voltage_mV = [v * 1000 for v in RxA_Rx_Voltage]

# Plot 1: TxD vs Rx Voltage (mV)
plt.figure(figsize=(8, 6))
plt.plot(TxD, TxD_Rx_Voltage_mV, marker='o', linestyle='-', linewidth=2)
plt.xlabel('TxD (cm)')
plt.ylabel('Rx-Side Voltage (mV)')
plt.grid(True)
plt.savefig('Graph_TxD_vs_RxVoltage_mV.png', dpi=600)
# plt.show()

# Plot 2: TxW vs Rx Voltage (mV)
plt.figure(figsize=(8, 6))
plt.plot(TxW, TxW_Rx_Voltage_mV, marker='s', linestyle='-', linewidth=2, color='green')
plt.xlabel('TxW (cm)')
plt.ylabel('Rx-Side Voltage (mV)')
plt.grid(True)
plt.savefig('Graph_TxW_vs_RxVoltage_mV.png', dpi=600)
# plt.show()

# Plot 3: TxG vs Rx Voltage (mV)
plt.figure(figsize=(8, 6))
plt.plot(TxG, TxG_Rx_Voltage_mV, marker='^', linestyle='-', linewidth=2, color='red')
plt.xlabel('TxG (cm)')
plt.ylabel('Rx Voltage (mV)')
plt.grid(True)
plt.savefig('Graph_TxG_vs_RxVoltage_mV.png', dpi=600)
# plt.show()

# Plot 4: RxH vs Rx Voltage (mV)
plt.figure(figsize=(8, 6))
plt.plot(RxH, RxH_Rx_Voltage_mV, marker='D', linestyle='-', linewidth=2, color='purple')
plt.xlabel('RxH (cm)')
plt.ylabel('Rx Voltage (mV)')
plt.grid(True)
plt.savefig('Graph_RxH_vs_RxVoltage_mV.png', dpi=600)
# plt.show()

# Plot 5: RxA vs Rx Voltage (mV)
plt.figure(figsize=(8, 6))
plt.plot(RxA, RxA_Rx_Voltage_mV, marker='v', linestyle='-', linewidth=2, color=(1, 0.5, 0))
plt.xlabel('RxA (Distance between Rx1 and Rx2) [cm]')
plt.ylabel('Rx Voltage (mV)')
plt.grid(True)
plt.savefig('Graph_RxA_vs_RxVoltage_Distance_mV.png', dpi=600)
# plt.show()

# --- Combined Figure with Subplots in a Single Row ---
fig, axes = plt.subplots(1, 5, figsize=(28, 5), constrained_layout=True)

subplot_labels = ['a)', 'b)', 'c)', 'd)', 'e)']
for ax, label in zip(axes, subplot_labels):
    ax.text(-0.15, 1.08, label, transform=ax.transAxes, fontsize=18, va='top', ha='right')  # fontweight removed

axes[0].plot(TxD, TxD_Rx_Voltage_mV, marker='o', linestyle='-', linewidth=2)
axes[0].set_xlabel('TxD (cm)')
axes[0].set_ylabel('Rx-Side Voltage (mV)')
axes[0].grid(True)

axes[1].plot(TxW, TxW_Rx_Voltage_mV, marker='s', linestyle='-', linewidth=2, color='green')
axes[1].set_xlabel('TxW (cm)')
axes[1].set_ylabel('Rx-Side Voltage (mV)')
axes[1].grid(True)

axes[2].plot(TxG, TxG_Rx_Voltage_mV, marker='^', linestyle='-', linewidth=2, color='red')
axes[2].set_xlabel('TxG (cm)')
axes[2].set_ylabel('Rx Voltage (mV)')
axes[2].grid(True)

axes[3].plot(RxH, RxH_Rx_Voltage_mV, marker='D', linestyle='-', linewidth=2, color='purple')
axes[3].set_xlabel('RxH (cm)')
axes[3].set_ylabel('Rx Voltage (mV)')
axes[3].grid(True)

axes[4].plot(RxA, RxA_Rx_Voltage_mV, marker='v', linestyle='-', linewidth=2, color=(1, 0.5, 0))
axes[4].set_xlabel('RxA (cm)')
axes[4].set_ylabel('Rx Voltage (mV)')
axes[4].grid(True)

plt.savefig('Combined_Graphs_Row_mV.png', dpi=600)
# plt.show()

