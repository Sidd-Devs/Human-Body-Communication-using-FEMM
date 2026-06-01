# -- coding: utf-8 --
"""
FEMM Implementation of Bio-Physical Modeling of Galvanic Human Body Communication
Based on: "Bio-Physical Modeling of Galvanic Human Body Communication in 
          Electro-Quasistatic Regime" (IEEE TBME 2022)
          
This implements the 2D planar skin-muscle model as described in Section III
and validated in Section VII of the paper.
"""

import femm
import math
import csv

def get_tissue_properties(frequency_khz):
    """
    Get frequency-dependent tissue properties
    Based on Gabriel et al. and IT'IS Foundation database
    Returns: (conductivity_S/m, relative_permittivity)
    """
    # Simplified frequency-dependent properties for skin and muscle
    # Based on references [15], [16] in the paper
    
    if frequency_khz <= 10:
        skin_props = (0.0002, 1100)      # Low conductivity at low freq
        muscle_props = (0.35, 10000)
    elif frequency_khz <= 100:
        skin_props = (0.05, 1200)
        muscle_props = (0.40, 7000)
    elif frequency_khz <= 400:
        skin_props = (0.15, 800)
        muscle_props = (0.45, 3000)
    elif frequency_khz <= 1000:
        skin_props = (0.25, 500)
        muscle_props = (0.55, 1500)
    else:
        skin_props = (0.35, 300)
        muscle_props = (0.65, 800)
    
    return {'skin': skin_props, 'muscle': muscle_props}

def calculate_muscle_impedances(r_electrode, s_separation, d_channel, theta_deg, 
                                h_muscle, rho_muscle):
    """
    Calculate muscle layer impedances Z_T, Z_R, Z_0 based on equations (6), (7), (8)
    
    Parameters:
    - r_electrode: electrode radius (cm)
    - s_separation: electrode pair separation (cm)
    - d_channel: channel length between Tx and Rx (cm)
    - theta_deg: angular position of receiver w.r.t. transmitter (degrees)
    - h_muscle: muscle layer thickness (cm)
    - rho_muscle: muscle resistivity (ohm-cm)
    
    Returns: (Z_T_muscle, Z_R_muscle, Z_0_muscle)
    """
    theta_rad = math.radians(theta_deg)
    
    # Calculate distances (from paper Section IV)
    r_AB = s_separation  # Tx electrode separation
    r_CD = s_separation  # Rx electrode separation
    r_AD = d_channel     # Channel length
    r_BC = d_channel
    
    sin_theta = math.sin(theta_rad)
    r_AC = math.sqrt(d_channel*2 + s_separation*2 - 2*d_channel*s_separation*sin_theta)
    r_BD = math.sqrt(d_channel*2 + s_separation*2 + 2*d_channel*s_separation*sin_theta)
    
    # Equation (6) - Z_T_muscle
    term1 = (r_AB*2) / (r_electrode*2)
    
    # Calculate the denominator term carefully
    d_sq = d_channel**2
    s_sq = s_separation**2
    cross_term = 2 * s_separation * d_channel * sin_theta
    denominator_term = (d_sq + s_sq)*2 - cross_term*2
    
    if denominator_term > 0:
        term2 = d_sq / math.sqrt(denominator_term)
        argument = term1 * term2
        if argument > 0:
            Z_T_muscle = (rho_muscle / (4 * math.pi * h_muscle)) * math.log(argument)
        else:
            Z_T_muscle = 1e-6  # Small value to avoid zero
    else:
        Z_T_muscle = 1e-6
    
    # Equation (7) - Z_R_muscle (same as Z_T for symmetric case)
    Z_R_muscle = Z_T_muscle
    
    # Equation (8) - Z_0_muscle
    numerator = r_AC * r_BD
    denominator = r_AD * r_BC
    if numerator > 0 and denominator > 0 and denominator != numerator:
        argument = numerator / denominator
        if argument > 0:
            Z_0_muscle = (rho_muscle / (2 * math.pi * h_muscle)) * math.log(argument)
        else:
            Z_0_muscle = 1e-6
    else:
        Z_0_muscle = 1e-6
    
    return Z_T_muscle, Z_R_muscle, Z_0_muscle

def run_galvanic_hbc_planar(electrode_radius=1.0, electrode_sep=5.0, channel_length=50.0,
                            theta=0, frequency_khz=400, skin_thickness=0.4, 
                            muscle_thickness=1.0, balanced=True, mismatch_factor=1.0):
    """
    Run Galvanic HBC simulation on planar skin-muscle structure
    
    Parameters:
    - electrode_radius: radius of circular electrodes (cm)
    - electrode_sep: separation between electrode pairs (cm)
    - channel_length: distance from Tx to Rx (cm)
    - theta: angular position of Rx w.r.t. Tx (degrees)
    - frequency_khz: signal frequency (kHz)
    - skin_thickness: thickness of skin layer (cm)
    - muscle_thickness: thickness of muscle layer (cm)
    - balanced: True for balanced/symmetric, False for unbalanced
    - mismatch_factor: return path capacitance mismatch (only for unbalanced)
    
    Returns: dict with simulation results
    """
    
    femm.openfemm()
    femm.newdocument(1)  # Electrostatics
    femm.ei_probdef('centimeters', 'planar', 1e-8, 7, 30)
    
    # Get frequency-dependent tissue properties
    tissue_props = get_tissue_properties(frequency_khz)
    skin_conductivity, skin_permittivity = tissue_props['skin']
    muscle_conductivity, muscle_permittivity = tissue_props['muscle']
    
    # Define materials
    femm.ei_addmaterial('Air', 1, 1, 0)
    femm.ei_addmaterial('Skin', skin_permittivity, 1, skin_conductivity)
    femm.ei_addmaterial('Muscle', muscle_permittivity, 1, muscle_conductivity)
    femm.ei_addmaterial('Copper', 1, 1, 5.99e7)
    
    # === GEOMETRY (2D Planar Structure as in Fig. 7 of paper) ===
    # Large planar structure: 200 cm × 200 cm
    structure_width = 200
    structure_height = structure_width
    
    # Position structure centered at origin
    x_min = -structure_width / 2
    x_max = structure_width / 2
    y_min = 0
    y_skin = skin_thickness
    y_muscle = y_skin + muscle_thickness
    y_max = y_muscle + 10  # Air gap above
    
    # Draw layers
    rectangles = {
        "Muscle": (x_min, y_skin, x_max, y_muscle),
        "Skin": (x_min, y_min, x_max, y_skin),
        "Air-Above": (x_min, y_muscle, x_max, y_max),
        "Air-Left": (x_min - 100, y_min - 100, x_min, y_max + 100),
        "Air-Right": (x_max, y_min - 100, x_max + 100, y_max + 100),
        "Air-Below": (x_min - 100, y_min - 100, x_max + 100, y_min),
        "Outer": (x_min - 200, y_min - 200, x_max + 200, y_max + 200)
    }
    
    for coords in rectangles.values():
        femm.ei_drawrectangle(*coords)
    
    # === ELECTRODE PLACEMENT ===
    # Transmitter at center (0, y_skin)
    tx_center_x = 0
    tx_center_y = y_skin
    
    tx_pos_x = tx_center_x - electrode_sep / 2
    tx_neg_x = tx_center_x + electrode_sep / 2
    
    # Receiver at distance 'channel_length' with angle 'theta'
    theta_rad = math.radians(theta)
    rx_center_x = channel_length * math.cos(theta_rad)
    rx_center_y = y_skin + channel_length * math.sin(theta_rad)
    
    # For planar model, keep Rx on skin surface
    rx_center_y = y_skin
    
    rx_pos_x = rx_center_x - electrode_sep / 2
    rx_neg_x = rx_center_x + electrode_sep / 2
    
    # Draw electrode circles on skin surface
    electrode_y = y_skin  # Electrodes sit on top of skin
    
    # Transmitter electrodes
    femm.ei_drawarc(tx_pos_x - electrode_radius, electrode_y, 
                    tx_pos_x + electrode_radius, electrode_y, 180, 1)
    femm.ei_drawarc(tx_pos_x + electrode_radius, electrode_y, 
                    tx_pos_x - electrode_radius, electrode_y, 180, 1)
    
    femm.ei_drawarc(tx_neg_x - electrode_radius, electrode_y, 
                    tx_neg_x + electrode_radius, electrode_y, 180, 1)
    femm.ei_drawarc(tx_neg_x + electrode_radius, electrode_y, 
                    tx_neg_x - electrode_radius, electrode_y, 180, 1)
    
    # Receiver electrodes
    femm.ei_drawarc(rx_pos_x - electrode_radius, electrode_y, 
                    rx_pos_x + electrode_radius, electrode_y, 180, 1)
    femm.ei_drawarc(rx_pos_x + electrode_radius, electrode_y, 
                    rx_pos_x - electrode_radius, electrode_y, 180, 1)
    
    femm.ei_drawarc(rx_neg_x - electrode_radius, electrode_y, 
                    rx_neg_x + electrode_radius, electrode_y, 180, 1)
    femm.ei_drawarc(rx_neg_x + electrode_radius, electrode_y, 
                    rx_neg_x - electrode_radius, electrode_y, 180, 1)
    
    # === BOUNDARY CONDITIONS ===
    femm.ei_addboundprop('Ground', 0, 0, 0, 0, 0)
    outer_edges = [
        (0, y_min - 200), (0, y_max + 200), 
        (x_min - 200, 0), (x_max + 200, 0)
    ]
    for x, y in outer_edges:
        femm.ei_selectsegment(x, y)
        femm.ei_setsegmentprop('Ground', 1, 1, 0, 0, '<None>')
        femm.ei_clearselected()
    
    # === MATERIAL ASSIGNMENT ===
    # Label materials
    femm.ei_addblocklabel(0, (y_skin + y_muscle) / 2)
    femm.ei_selectlabel(0, (y_skin + y_muscle) / 2)
    femm.ei_setblockprop('Muscle', 1, 1, 0)
    femm.ei_clearselected()
    
    femm.ei_addblocklabel(0, y_skin / 2)
    femm.ei_selectlabel(0, y_skin / 2)
    femm.ei_setblockprop('Skin', 1, 1, 0)
    femm.ei_clearselected()
    
    femm.ei_addblocklabel(0, y_muscle + 5)
    femm.ei_selectlabel(0, y_muscle + 5)
    femm.ei_setblockprop('Air', 1, 1, 0)
    femm.ei_clearselected()
    
    # Label electrodes
    femm.ei_addblocklabel(tx_pos_x, electrode_y)
    femm.ei_selectlabel(tx_pos_x, electrode_y)
    femm.ei_setblockprop('<No Mesh>', 1, 1, 0)
    femm.ei_clearselected()
    
    femm.ei_addblocklabel(tx_neg_x, electrode_y)
    femm.ei_selectlabel(tx_neg_x, electrode_y)
    femm.ei_setblockprop('<No Mesh>', 1, 1, 0)
    femm.ei_clearselected()
    
    femm.ei_addblocklabel(rx_pos_x, electrode_y)
    femm.ei_selectlabel(rx_pos_x, electrode_y)
    femm.ei_setblockprop('<No Mesh>', 1, 1, 0)
    femm.ei_clearselected()
    
    femm.ei_addblocklabel(rx_neg_x, electrode_y)
    femm.ei_selectlabel(rx_neg_x, electrode_y)
    femm.ei_setblockprop('<No Mesh>', 1, 1, 0)
    femm.ei_clearselected()
    
    # === CONDUCTOR PROPERTIES ===
    # Galvanic excitation: 1V differential
    if balanced:
        femm.ei_addconductorprop('eTx-Pos', 0.5, 0, 1)   # +0.5V
        femm.ei_addconductorprop('eTx-Neg', -0.5, 0, 1)  # -0.5V
    else:
        femm.ei_addconductorprop('eTx-Pos', 0.5, 0, 1)
        femm.ei_addconductorprop('eTx-Neg', -0.5, 0, 1)
    
    femm.ei_addconductorprop('eRx-Pos', 0, 0, 0)  # Floating
    femm.ei_addconductorprop('eRx-Neg', 0, 0, 0)  # Floating
    
    # Assign conductors to electrodes
    femm.ei_selectarcsegment(tx_pos_x, electrode_y + electrode_radius)
    femm.ei_setarcsegmentprop(1, '<None>', 0, 0, 'eTx-Pos')
    femm.ei_clearselected()
    
    femm.ei_selectarcsegment(tx_neg_x, electrode_y + electrode_radius)
    femm.ei_setarcsegmentprop(1, '<None>', 0, 0, 'eTx-Neg')
    femm.ei_clearselected()
    
    femm.ei_selectarcsegment(rx_pos_x, electrode_y + electrode_radius)
    femm.ei_setarcsegmentprop(1, '<None>', 0, 0, 'eRx-Pos')
    femm.ei_clearselected()
    
    femm.ei_selectarcsegment(rx_neg_x, electrode_y + electrode_radius)
    femm.ei_setarcsegmentprop(1, '<None>', 0, 0, 'eRx-Neg')
    femm.ei_clearselected()
    
    # === SOLVE ===
    filename = "galvanic_planar_d{}_f{}kHz.fee".format(int(channel_length), int(frequency_khz))
    print("Saving model as: {}".format(filename))
    
    try:
        femm.ei_saveas(filename)
        print("Analyzing...")
        femm.ei_analyze(1)
        print("Loading solution...")
        femm.ei_loadsolution()
        print("Solution loaded successfully!")
    except Exception as e:
        print("Error during analysis: {}".format(str(e)))
        femm.closefemm()
        return None
    
    # === GET RESULTS ===
    try:
        v_tx_pos = femm.eo_getconductorproperties('eTx-Pos')[0]
        v_tx_neg = femm.eo_getconductorproperties('eTx-Neg')[0]
        v_rx_pos = femm.eo_getconductorproperties('eRx-Pos')[0]
        v_rx_neg = femm.eo_getconductorproperties('eRx-Neg')[0]
        
        print("Voltages retrieved successfully!")
    except Exception as e:
        print("Error getting conductor properties: {}".format(str(e)))
        femm.closefemm()
        return None
    
    v_tx = v_tx_pos - v_tx_neg
    v_rx = v_rx_pos - v_rx_neg
    
    # Calculate gain in dB (Equation 15 for balanced case)
    if v_tx != 0 and v_rx != 0:
        gain_db = 20 * math.log10(abs(v_rx / v_tx))
    else:
        gain_db = float('-inf')
    
    # Calculate theoretical values using equations from paper
    # Skin impedance parameters
    epsilon_0 = 8.854e-14  # F/cm
    epsilon_skin = skin_permittivity * epsilon_0
    area = math.pi * electrode_radius**2
    
    C_skin = epsilon_skin * area / skin_thickness
    R_skin = skin_thickness / (skin_conductivity * area)
    
    # Muscle resistivity
    rho_muscle = 1 / muscle_conductivity  # ohm-cm
    
    # Calculate muscle impedances
    Z_T, Z_R, Z_0 = calculate_muscle_impedances(
        electrode_radius, electrode_sep, channel_length, theta,
        muscle_thickness, rho_muscle
    )
    
    R_muscle = Z_0 + 2 * Z_T
    
    # Theoretical gain (Equation 15)
    if R_muscle > 0 and R_skin > 0:
        freq_hz = frequency_khz * 1000
        omega = 2 * math.pi * freq_hz
        
        # First term: DC division
        term1 = R_muscle / (2 * R_skin)
        
        # Second term: Frequency dependent
        omega_c_r = omega * C_skin * R_skin
        omega_c_r_half = 0.5 * omega * C_skin * R_muscle
        
        numerator = 1 + omega_c_r * omega_c_r
        denominator = 1 + omega_c_r_half * omega_c_r_half
        term2 = math.sqrt(numerator / denominator)
        
        # Third term: Geometry dependent
        s_over_d = electrode_sep / channel_length
        theta_rad_calc = math.radians(theta)
        sin_theta_calc = math.sin(theta_rad_calc)
        
        # Calculate geometry term step by step
        s_over_d_sq = s_over_d * s_over_d
        part1 = 1 + s_over_d_sq
        part1_sq = part1 * part1
        
        two_s_over_d_sin = 2 * s_over_d * sin_theta_calc
        part2 = two_s_over_d_sin * two_s_over_d_sin
        
        geometry_numerator = part1_sq - part2
        
        if geometry_numerator > 0:
            geom_term = math.sqrt(geometry_numerator)
            
            if geom_term > 0:
                log_numerator = math.log(geom_term)
            else:
                log_numerator = 0
            
            electrode_sep_sq = electrode_sep * electrode_sep
            electrode_radius_sq = electrode_radius * electrode_radius
            log_denominator = math.log(electrode_sep_sq / electrode_radius_sq)
            
            if abs(log_denominator) > 1e-9:
                term3 = abs(log_numerator / log_denominator)
            else:
                term3 = 1.0
        else:
            term3 = 1.0
        
        theoretical_gain = term1 * term2 * term3
        
        if theoretical_gain > 0:
            theoretical_gain_db = 20 * math.log10(theoretical_gain)
        else:
            theoretical_gain_db = float('-inf')
    else:
        theoretical_gain_db = float('-inf')
    
    print("\n=== Galvanic HBC Planar Simulation Results ===")
    print("Channel length: {} cm".format(channel_length))
    print("Electrode radius: {} cm".format(electrode_radius))
    print("Electrode separation: {} cm".format(electrode_sep))
    print("Frequency: {} kHz".format(frequency_khz))
    print("Balanced: {}".format(balanced))
    print("\nVoltages:")
    print("  Tx differential: {:.6f} V".format(v_tx))
    print("  Rx differential: {:.6f} V".format(v_rx))
    print("\nGain:")
    print("  Simulated: {:.2f} dB".format(gain_db))
    print("  Theoretical (Eq. 15): {:.2f} dB".format(theoretical_gain_db))
    print("  Error: {:.2f} dB".format(abs(gain_db - theoretical_gain_db)))
    print("\nImpedance parameters:")
    print("  R_skin: {:.2f} Ohm".format(R_skin))
    print("  C_skin: {:.2f} pF".format(C_skin*1e12))
    print("  Z_T_muscle: {:.2f} Ohm".format(Z_T))
    print("  Z_0_muscle: {:.2f} Ohm".format(Z_0))
    print("  R_muscle: {:.2f} Ohm".format(R_muscle))
    
    # Save visualization
    try:
        femm.ei_zoomnatural()
        bmp_filename = "galvanic_planar_d{}.bmp".format(int(channel_length))
        femm.ei_savebitmap(bmp_filename)
        print("\nBitmap saved as: {}".format(bmp_filename))
    except Exception as e:
        print("Warning: Could not save bitmap: {}".format(str(e)))
    
    return {
        'channel_length': channel_length,
        'frequency_khz': frequency_khz,
        'v_tx': v_tx,
        'v_rx': v_rx,
        'gain_db': gain_db,
        'theoretical_gain_db': theoretical_gain_db,
        'error_db': abs(gain_db - theoretical_gain_db),
        'R_skin': R_skin,
        'C_skin': C_skin,
        'Z_T_muscle': Z_T,
        'Z_0_muscle': Z_0,
        'R_muscle': R_muscle
    }


# === MAIN EXECUTION ===
if __name__ == "_main_":
    print("=" * 60)
    print("Galvanic HBC Bio-Physical Model Simulation")
    print("Based on IEEE TBME 2022 paper by Modak et al.")
    print("=" * 60)
    
    # Check if FEMM is available
    try:
        import femm
        print("\nFEMM module loaded successfully!")
    except ImportError:
        print("\nERROR: FEMM module not found!")
        print("Please install FEMM and ensure pyFEMM is in your Python path")
        exit(1)
    
    # === TEST SIMULATION FIRST ===
    print("\n### Running Test Simulation ###")
    print("Testing with: 50 cm channel, 1 cm electrode, 400 kHz...")
    
    result_test = run_galvanic_hbc_planar(
        electrode_radius=1.0,
        electrode_sep=10.0,
        channel_length=50.0,
        frequency_khz=400,
        balanced=True
    )
    
    if result_test is None:
        print("\nERROR: Test simulation failed!")
        print("Please check FEMM installation and try again")
        exit(1)
    
    print("\nTest simulation successful!")
    femm.closefemm()
    
    # Ask user if they want to continue with full sweep
    print("\n" + "=" * 60)
    response = input("Test passed! Run full distance sweep? (y/n): ")
    
    if response.lower() != 'y':
        print("Exiting...")
        exit(0)
    
    # === EXPERIMENT 1: Distance-dependent response (Fig. 7b) ===
    print("\n### Experiment 1: Channel Gain vs Distance ###")
    distances = [10, 20, 30, 40, 50, 60, 80, 100]
    results_distance = []
    
    for i, d in enumerate(distances):
        print("\n[{}/{}] Simulating channel length: {} cm...".format(i+1, len(distances), d))
        result = run_galvanic_hbc_planar(
            electrode_radius=1.0,
            electrode_sep=10.0,
            channel_length=d,
            frequency_khz=400,
            balanced=True
        )
        
        if result is not None:
            results_distance.append(result)
        else:
            print("WARNING: Simulation failed for distance {} cm".format(d))
        
        femm.closefemm()
    
    # Save results to CSV
    if len(results_distance) > 0:
        csv_filename = 'galvanic_distance_sweep.csv'
        print("\nSaving results to {}...".format(csv_filename))
        
        with open(csv_filename, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['Distance(cm)', 'Gain(dB)', 'Theoretical_Gain(dB)', 'Error(dB)'])
            for r in results_distance:
                writer.writerow([r['channel_length'], r['gain_db'], 
                               r['theoretical_gain_db'], r['error_db']])
        
        print("\n" + "=" * 60)
        print("Simulation complete!")
        print("Results saved to: {}".format(csv_filename))
        print("Total simulations: {}".format(len(results_distance)))
        print("=" * 60)
    else:
        print("\nERROR: No successful simulations completed")
        print("Please check FEMM configuration and try again")