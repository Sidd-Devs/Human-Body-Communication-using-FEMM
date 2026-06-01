# -- coding: utf-8 --
"""
Config-3: Tx-Ground electrode positioned ABOVE Tx-Signal electrode (vertically stacked)
         AND Rx-Gnd positioned as a vertical bar to the LEFT of Rx-Signal
"""

import femm
import csv

# === Helper functions ===
def assign_segments(boundary=None, conductor=None, points=[]):
    for x, y in points:
        femm.ei_selectsegment(x, y)
        femm.ei_setsegmentprop(boundary or '<None>', 1, 1, 0, 0, conductor or '<None>')
        femm.ei_clearselected()

def label_block(x, y, material):
    femm.ei_addblocklabel(x, y)
    femm.ei_selectlabel(x, y)
    femm.ei_setblockprop(material, 1, 1, 0)
    femm.ei_clearselected()

def get_rectangle_edges(x1, y1, x2, y2):
    return [
        ((x1 + x2) / 2, y1),
        ((x1 + x2) / 2, y2),
        (x1, (y1 + y2) / 2),
        (x2, (y1 + y2) / 2),
    ]

def get_rectangle_center(x1, y1, x2, y2):
    return (x1 + x2) / 2, (y1 + y2) / 2

def get_rectangle_topleft(x1, y1, x2, y2):
    left, right = min(x1, x2), max(x1, x2)
    bottom, top = min(y1, y2), max(y1, y2)
    dx = 0.01 * (right - left)
    dy = 0.01 * (top - bottom)
    return (left + dx, top - dy)

# === Main FEMM model function ===
def run_with_params(params):
    femm.openfemm()
    femm.newdocument(1)
    femm.ei_probdef('centimeters', 'planar', 1e-8, 7, 30)

    TxD = params['TxD']
    TxW = params['TxW']
    TxG = params['TxG']
    TxT = params['TxT']
    RxT = params['RxT']
    RxH = params['RxH']
    RxW = params['RxW']
    RxA = params['RxA']  # Rx-Gnd anchor position

    # === CONFIG-3 GEOMETRY ===
    # Tx: Vertically stacked (Tx-Ground ABOVE Tx-Signal)
    # Rx: Rx-Gnd is a vertical bar to the LEFT of Rx-Signal
    
    rectangles = {
        "Head": (-12.5, 19.4, -1.5, 8.5),
        "Body": (-14, 8.4, 0, -38.9),
        "Leg": (-12, -39.0, -2, -109),

        "Skin-Bottom":   (0, 0.000, 70, 0.063),
        "Fat-Lower":     (0, 0.063, 70, 0.520),
        "Muscle-Lower":  (0, 0.520, 70, 1.775),
        "Bone-Lower":    (0, 1.775, 70, 2.127), 
        "Bone-Marrow":   (0, 2.127, 70, 2.500),
        "Bone-Upper":    (0, 2.500, 70, 2.852),
        "Muscle-Upper":  (0, 2.852, 70, 4.107),
        "Fat-Upper":     (0, 4.107, 70, 4.564),
        "Skin-Top":      (0, 4.564, 70, 4.627),
    
        # CONFIG-3: Tx electrodes vertically stacked
        # Tx-Signal sits on top of skin at y = 4.627
        "Tx-Signal": (70-TxD-TxW, 4.627, 70-TxD, 4.627+TxT),
        
        # Tx-Ground is ABOVE Tx-Signal, separated by gap TxG (same as Config-2)
        "Tx-Ground": (70-TxD-TxW, 4.627+TxT+TxG, 70-TxD, 4.627+TxT+TxG+TxT),

        # CONFIG-3: Rx electrodes - DIFFERENT from Config-1 and Config-2
        # Rx-Signal: Horizontal bar at bottom of foot
        "Rx-Signal": (55, 0, 70, 0-RxT),
        
        # Rx-Gnd: VERTICAL bar to the LEFT of Rx-Signal
        # Anchored at y = RxA, extends downward for RxH
        "Rx-Gnd": (55, RxA, 55-RxT, RxA - RxH),

        # Hub: Wooden block between Rx-Signal and the table area
        "Hub": (55, 0-RxT, 55+RxW, RxA),  # From below Rx-Signal to top of Rx-Gnd

        # Wood table: Below the hub area
        "Wood": (55, RxA-RxH, 90, -109),        
        
        "Outer": (-610, 610, 610, -610)
    }

    for coords in rectangles.values():
        femm.ei_drawrectangle(*coords)

    femm.ei_addboundprop('Ground', 0, 0, 0, 0, 0)
    assign_segments(boundary='Ground', points=get_rectangle_edges(*rectangles["Outer"]))

    femm.ei_addmaterial('Air', 1, 1, 0)
    femm.ei_addmaterial('Skin', 2.0e4, 1, 0)
    femm.ei_addmaterial('Fat', 1.0e2, 1, 0)
    femm.ei_addmaterial('Muscle', 8.0e3, 1, 0)
    femm.ei_addmaterial('Bone', 2.5e2, 1, 0)
    femm.ei_addmaterial('Bone-Marrow', 2.5e2, 1, 0)
    femm.ei_addmaterial('Wood', 2.0, 1, 0)

    conductor_regions = ["Head", "Body", "Leg", "Tx-Signal", "Tx-Ground", "Rx-Signal", "Rx-Gnd"]
    
    material_map = {
        "Skin-Bottom": "Skin",
        "Skin-Top": "Skin",
        "Fat-Lower": "Fat",
        "Fat-Upper": "Fat",
        "Muscle-Lower": "Muscle",
        "Muscle-Upper": "Muscle",
        "Bone-Upper": "Bone",
        "Bone-Lower": "Bone",
        "Bone-Marrow": "Bone-Marrow",
        "Wood": "Wood",
        "Hub": "Wood"
    }

    for name in conductor_regions:
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), '<No Mesh>')

    for name, mat in material_map.items():
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), mat)

    label_block(*get_rectangle_topleft(*rectangles["Outer"]), 'Air')
   
    femm.ei_addconductorprop('eTx-Signal', 5, 0, 1)
    femm.ei_addconductorprop('eTx-Ground', 0, 0, 1)
    femm.ei_addconductorprop('eRx-Signal', 0, 0, 0)
    femm.ei_addconductorprop('eRx-Gnd', 0, 0, 0)
    femm.ei_addconductorprop('eHead', 0, 0, 0)
    femm.ei_addconductorprop('eBody', 0, 0, 0)
    femm.ei_addconductorprop('eLeg', 0, 0, 0)

    assign_segments(conductor='eTx-Ground', points=get_rectangle_edges(*rectangles["Tx-Ground"]))
    assign_segments(conductor='eTx-Signal', points=get_rectangle_edges(*rectangles["Tx-Signal"]))
    assign_segments(conductor='eRx-Gnd', points=get_rectangle_edges(*rectangles["Rx-Gnd"]))
    assign_segments(conductor='eRx-Signal', points=get_rectangle_edges(*rectangles["Rx-Signal"]))
    assign_segments(conductor='eHead', points=get_rectangle_edges(*rectangles["Head"]))
    assign_segments(conductor='eBody', points=get_rectangle_edges(*rectangles["Body"]))
    assign_segments(conductor='eLeg', points=get_rectangle_edges(*rectangles["Leg"]))

    femm.ei_saveas("temp_sim_config3.fee")
    femm.ei_analyze(1)
    femm.ei_loadsolution()

    v_rx_signal = femm.eo_getconductorproperties('eRx-Signal')[0]
    v_rx_gnd = femm.eo_getconductorproperties('eRx-Gnd')[0]
    return v_rx_signal - v_rx_gnd

# === Sweep Controller ===
defaults = {
    'TxD': 20,
    'TxW': 3,
    'TxG': 3,
    'RxH': 30,
    'RxA': -10,    # Rx-Gnd anchor position
    'TxT': 0.2,
    'RxT': 0.2,
    'RxW': 3,
}

sweeps = {
    'TxD': list(range(10, 41, 31)),
    'TxW': list(range(1, 11, 11)),
    'TxG': list(range(1, 11, 11)),
    'RxH': list(range(10, 51, 41)),
    'RxA': list(range(-5, -41, -36)),
    'RxW': list(range(5, 35, 30))
}

output_file = "results_config3.csv"

with open(output_file, mode='w', newline='') as f:
    writer = csv.writer(f)
    headers = ["SweepParam"] + list(defaults.keys()) + ["Rx_Voltage"]
    writer.writerow(headers)

    for param, values in sweeps.items():
        for val in values:
            print(f"[INFO] Sweeping {param} = {val}")
            current_params = defaults.copy()
            current_params[param] = val

            v_diff_rx = run_with_params(current_params)
            writer.writerow([param] + [current_params[key] for key in defaults] + [f"{v_diff_rx:.6f}"])

femm.closefemm()