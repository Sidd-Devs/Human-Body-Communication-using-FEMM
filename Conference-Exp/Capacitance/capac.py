import femm
import numpy as np

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
    width = right - left
    height = top - bottom
    dx = 0.01 * width
    dy = 0.01 * height
    return (left + dx, top - dy)

def calculate_capacitance_matrix():
    """
    Calculate ALL coupling capacitances using multiple simulation method.
    This is the ONLY correct way in FEMM electrostatics.
    """
    
    print("="*70)
    print("COMPLETE CAPACITANCE MATRIX CALCULATION FOR HBC")
    print("="*70)
    print("\nWe need 4 simulations (one per electrode at 1V, others at 0V)")
    print("This gives us the complete 4x4 capacitance matrix.")
    print("="*70)
    
    # Parameters
    TxD = 20
    TxW = 3
    TxG = 3
    RxH = 30
    RxA = -10
    RxT = 0.2
    TxT = 0.2
    
    # Geometry
    rectangles = {
        "Head": (-12.5, 19.4, -1.5, 8.5),
        "Body": (-14, 8.4, 0, -38.9),
        "Leg": (-12, -39.0, -2, -109),
        "Skin-Bottom": (0, 0.000, 70, 0.063),
        "Fat-Lower": (0, 0.063, 70, 0.520),
        "Muscle-Lower": (0, 0.520, 70, 1.775),
        "Bone-Lower": (0, 1.775, 70, 2.127),
        "Bone-Marrow": (0, 2.127, 70, 2.500),
        "Bone-Upper": (0, 2.500, 70, 2.852),
        "Muscle-Upper": (0, 2.852, 70, 4.107),
        "Fat-Upper": (0, 4.107, 70, 4.564),
        "Skin-Top": (0, 4.564, 70, 4.627),
        "Tx-Signal": (70-TxD-TxW, 4.627+TxT, 70-TxD, 4.627),
        "Tx-Ground": (70-TxD-2*TxW-TxG, 4.627+TxT, 70-TxD-TxW-TxG, 4.627),
        "Rx-Signal": (55, 0, 70, 0-RxT),
        "Rx-Gnd": (55, RxA, 55-RxT, RxA - RxH),
        "Wood": (55, 0-RxT, 90, -109),
        "Outer": (-610, 610, 610, -610)
    }
    
    conductor_regions = ["Head", "Body", "Leg", "Tx-Signal", "Tx-Ground", "Rx-Signal", "Rx-Gnd"]
    material_map = {
        "Skin-Bottom": "Skin", "Skin-Top": "Skin",
        "Fat-Lower": "Fat", "Fat-Upper": "Fat",
        "Muscle-Lower": "Muscle", "Muscle-Upper": "Muscle",
        "Bone-Upper": "Bone", "Bone-Lower": "Bone",
        "Bone-Marrow": "Bone-Marrow", "Wood": "Wood"
    }
    
    # Store charges from all 4 simulations
    # Rows = which electrode is excited (1V)
    # Cols = charge measured on each electrode
    charge_matrix = np.zeros((4, 4))
    electrode_names = ['Tx-Signal', 'Tx-Ground', 'Rx-Signal', 'Rx-Gnd']
    conductor_names = ['eTx-Signal', 'eTx-Ground', 'eRx-Signal', 'eRx-Gnd']
    
    # Run 4 simulations
    for excite_idx in range(4):
        print(f"\n{'='*70}")
        print(f"SIMULATION {excite_idx+1}: {electrode_names[excite_idx]} = 1V, all others = 0V")
        print(f"{'='*70}")
        
        femm.openfemm()
        femm.newdocument(1)
        femm.ei_probdef('centimeters', 'planar', 1e-8, 7, 30)
        
        # Draw geometry
        for coords in rectangles.values():
            femm.ei_drawrectangle(*coords)
        
        # Boundary
        femm.ei_addboundprop('Ground', 0, 0, 0, 0, 0)
        assign_segments(boundary='Ground', points=get_rectangle_edges(*rectangles["Outer"]))
        
        # Materials
        femm.ei_addmaterial('Air', 1, 1, 0)
        femm.ei_addmaterial('Skin', 2.0e4, 1, 0)
        femm.ei_addmaterial('Fat', 1.0e2, 1, 0)
        femm.ei_addmaterial('Muscle', 8.0e3, 1, 0)
        femm.ei_addmaterial('Bone', 2.5e2, 1, 0)
        femm.ei_addmaterial('Bone-Marrow', 2.5e2, 1, 0)
        femm.ei_addmaterial('Wood', 2.0, 1, 0)
        
        for name in conductor_regions:
            if name in rectangles:
                label_block(*get_rectangle_center(*rectangles[name]), '<No Mesh>')
        
        for name, mat in material_map.items():
            if name in rectangles:
                label_block(*get_rectangle_center(*rectangles[name]), mat)
        
        label_block(*get_rectangle_topleft(*rectangles["Outer"]), 'Air')
        
        # Set voltages: excited electrode = 1V, all others = 0V
        voltages = [0, 0, 0, 0]
        voltages[excite_idx] = 1
        
        femm.ei_addconductorprop('eTx-Signal', voltages[0], 0, 1)
        femm.ei_addconductorprop('eTx-Ground', voltages[1], 0, 1)
        femm.ei_addconductorprop('eRx-Signal', voltages[2], 0, 1)
        femm.ei_addconductorprop('eRx-Gnd', voltages[3], 0, 1)
        femm.ei_addconductorprop('eHead', 0, 0, 0)
        femm.ei_addconductorprop('eBody', 0, 0, 0)
        femm.ei_addconductorprop('eLeg', 0, 0, 0)
        
        # Assign segments
        assign_segments(conductor='eTx-Ground', points=get_rectangle_edges(*rectangles["Tx-Ground"]))
        assign_segments(conductor='eTx-Signal', points=get_rectangle_edges(*rectangles["Tx-Signal"]))
        assign_segments(conductor='eRx-Gnd', points=get_rectangle_edges(*rectangles["Rx-Gnd"]))
        assign_segments(conductor='eRx-Signal', points=get_rectangle_edges(*rectangles["Rx-Signal"]))
        assign_segments(conductor='eHead', points=get_rectangle_edges(*rectangles["Head"]))
        assign_segments(conductor='eBody', points=get_rectangle_edges(*rectangles["Body"]))
        assign_segments(conductor='eLeg', points=get_rectangle_edges(*rectangles["Leg"]))
        
        # Solve
        femm.ei_saveas(f'hbc_cap_matrix_{excite_idx+1}.fee')
        femm.ei_analyze(1)
        femm.ei_loadsolution()
        
        # Get charges on all 4 electrodes
        print(f"\nCharges when {electrode_names[excite_idx]} = 1V:")
        for meas_idx in range(4):
            props = femm.eo_getconductorproperties(conductor_names[meas_idx])
            voltage = props[0]
            charge = props[1]
            charge_matrix[excite_idx, meas_idx] = charge
            print(f"  {electrode_names[meas_idx]:12s}: V={voltage:6.3f}V, Q={charge:+.6e}C")
        
        femm.ei_close()
        femm.closefemm()
    
    # Calculate capacitance matrix: C[i,j] = Q[i,j] / V[j]
    # where V[j] = 1V, so C[i,j] = Q[i,j]
    print("\n" + "="*70)
    print("CAPACITANCE MATRIX [F]")
    print("="*70)
    print("Rows = charge on electrode, Cols = voltage applied to electrode")
    print(f"\n{'':12s}", end="")
    for name in electrode_names:
        print(f"{name:>15s}", end="")
    print()
    print("-"*70)
    
    for i, row_name in enumerate(electrode_names):
        print(f"{row_name:12s}", end="")
        for j in range(4):
            print(f"{charge_matrix[i,j]:+15.6e}", end="")
        print()
    
    # Extract specific coupling capacitances for HBC circuit model
    print("\n" + "="*70)
    print("HBC COUPLING CAPACITANCES")
    print("="*70)
    
    # Self-capacitances (diagonal elements)
    C_TxS_self = charge_matrix[0, 0]  # Charge on Tx-Signal when Tx-Signal = 1V
    C_TxG_self = charge_matrix[1, 1]
    C_RxS_self = charge_matrix[2, 2]
    C_RxG_self = charge_matrix[3, 3]
    
    # Mutual capacitances (off-diagonal)
    C_TxS_TxG = -charge_matrix[1, 0]  # Negative because it's opposite sign
    C_TxS_RxS = -charge_matrix[2, 0]  # Forward coupling (C_F)
    C_TxS_RxG = -charge_matrix[3, 0]
    C_TxG_RxS = -charge_matrix[2, 1]
    C_TxG_RxG = -charge_matrix[3, 1]  # Return path coupling (C_R)
    C_RxS_RxG = -charge_matrix[3, 2]  # Load capacitance (C_L)
    
    print(f"\n1. SELF-CAPACITANCES:")
    print(f"   C_TxS (Tx-Signal):  {C_TxS_self:.6e} F = {C_TxS_self*1e12:8.3f} pF")
    print(f"   C_TxG (Tx-Ground):  {C_TxG_self:.6e} F = {C_TxG_self*1e12:8.3f} pF")
    print(f"   C_RxS (Rx-Signal):  {C_RxS_self:.6e} F = {C_RxS_self*1e12:8.3f} pF")
    print(f"   C_RxG (Rx-Ground):  {C_RxG_self:.6e} F = {C_RxG_self*1e12:8.3f} pF")
    
    print(f"\n2. TRANSMITTER COUPLING:")
    print(f"   C_TxS↔TxG:          {C_TxS_TxG:.6e} F = {C_TxS_TxG*1e12:8.3f} pF")
    
    print(f"\n3. FORWARD PATH (Tx → Rx through body):")
    print(f"   C_F (TxS→RxS):      {C_TxS_RxS:.6e} F = {C_TxS_RxS*1e12:8.3f} pF  ← MAIN SIGNAL")
    print(f"   C_TxS→RxG:          {C_TxS_RxG:.6e} F = {C_TxS_RxG*1e12:8.3f} pF")
    print(f"   C_TxG→RxS:          {C_TxG_RxS:.6e} F = {C_TxG_RxS*1e12:8.3f} pF")
    
    print(f"\n4. RETURN PATH (through ground/table):")
    print(f"   C_R (TxG→RxG):      {C_TxG_RxG:.6e} F = {C_TxG_RxG*1e12:8.3f} pF  ← RETURN PATH")
    
    print(f"\n5. RECEIVER LOAD:")
    print(f"   C_L (RxS↔RxG):      {C_RxS_RxG:.6e} F = {C_RxS_RxG*1e12:8.3f} pF  ← LOAD CAP")
    
    # Now simulate ACTUAL HBC with Tx=5V, Rx floating to get channel gain
    print("\n" + "="*70)
    print("ACTUAL HBC CHANNEL GAIN SIMULATION")
    print("="*70)
    print("Tx-Signal = 5V, Tx-Ground = 0V, Rx electrodes = FLOATING")
    
    femm.openfemm()
    femm.newdocument(1)
    femm.ei_probdef('centimeters', 'planar', 1e-8, 7, 30)
    
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
    
    for name in conductor_regions:
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), '<No Mesh>')
    
    for name, mat in material_map.items():
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), mat)
    
    label_block(*get_rectangle_topleft(*rectangles["Outer"]), 'Air')
    
    # REALISTIC HBC: Tx transmits, Rx receives (floating)
    femm.ei_addconductorprop('eTx-Signal', 5, 0, 1)
    femm.ei_addconductorprop('eTx-Ground', 0, 0, 1)
    femm.ei_addconductorprop('eRx-Signal', 0, 0, 0)  # FLOATING
    femm.ei_addconductorprop('eRx-Gnd', 0, 0, 0)     # FLOATING
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
    
    femm.ei_saveas('hbc_actual.fee')
    femm.ei_analyze(1)
    femm.ei_loadsolution()
    femm.ei_savebitmap('hbc_actual.bmp')
    
    v_rx_signal = femm.eo_getconductorproperties('eRx-Signal')[0]
    v_rx_gnd = femm.eo_getconductorproperties('eRx-Gnd')[0]
    v_rx_diff = v_rx_signal - v_rx_gnd
    gain_dB = 20 * np.log10(abs(v_rx_diff) / 5.0) if abs(v_rx_diff) > 0 else -np.inf
    
    print(f"\nReceived Voltages:")
    print(f"  V_Rx-Signal = {v_rx_signal:.6f} V")
    print(f"  V_Rx-Ground = {v_rx_gnd:.6f} V")
    print(f"  V_Rx (differential) = {v_rx_diff:.6f} V")
    print(f"  Channel Gain = {gain_dB:.2f} dB")
    
    femm.ei_close()
    femm.closefemm()
    
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    print(f"Forward Coupling (C_F):     {C_TxS_RxS*1e12:8.3f} pF")
    print(f"Return Path (C_R):          {C_TxG_RxG*1e12:8.3f} pF")
    print(f"Load Capacitance (C_L):     {C_RxS_RxG*1e12:8.3f} pF")
    print(f"Received Voltage:           {v_rx_diff:.6f} V")
    print(f"Channel Gain:               {gain_dB:.2f} dB")
    print("="*70)
    
    return {
        'C_matrix': charge_matrix,
        'C_F': C_TxS_RxS,
        'C_R': C_TxG_RxG,
        'C_L': C_RxS_RxG,
        'V_Rx': v_rx_diff,
        'Gain_dB': gain_dB
    }

if __name__ == "__main__":
    results = calculate_capacitance_matrix()