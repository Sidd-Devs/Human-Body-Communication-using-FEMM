import femm

def assign_segments(boundary=None, conductor=None, points=[]):
    for x, y in points:
        femm.ei_selectsegment(x, y)
        femm.ei_setsegmentprop(boundary or '<None>', 1, 1, 0, 0, conductor or '<None>')
        femm.ei_clearselected()

def label_block(x, y, material):
    femm.ei_addblocklabel(x, y)  # (x, y)
    femm.ei_selectlabel(x, y)    # (x, y)
    femm.ei_setblockprop(material, 1, 1, 0)  # (material, automesh, meshsize, group)
    femm.ei_clearselected()

def get_rectangle_edges(x1, y1, x2, y2):
    """Returns midpoints of edges of a rectangle defined by (x1, y1, x2, y2)."""
    return [
        ((x1 + x2) / 2, y1),  # Bottom edge midpoint
        ((x1 + x2) / 2, y2),  # Top edge midpoint
        (x1, (y1 + y2) / 2),  # Left edge midpoint
        (x2, (y1 + y2) / 2),  # Right edge midpoint
    ]

def get_rectangle_center(x1, y1, x2, y2):
    """
    Returns the (x, y) center point of a rectangle defined by (x1, y1) and (x2, y2).
    Useful for placing FEMM block labels inside regions.

    Parameters:
        x1, y1: Coordinates of one corner (e.g., bottom-left)
        x2, y2: Coordinates of opposite corner (e.g., top-right)

    Returns:
        (x_center, y_center): Tuple of float center coordinates
    """
    x_center = (x1 + x2) / 2
    y_center = (y1 + y2) / 2
    return x_center, y_center

def get_rectangle_topleft(x1, y1, x2, y2):
    """
    Returns an inset point from top-left corner of a rectangle.

    Returns:
        (x, y): Inset coordinate from the given corner.
    """
    # dx_percent: Inset distance from the vertical edge as % of width (0–100).
    # dy_percent: Inset distance from the horizontal edge as % of height (0–100)
    corner="top-left"
    dx_percent=1
    dy_percent=1

    left, right = min(x1, x2), max(x1, x2)
    bottom, top = min(y1, y2), max(y1, y2)
    width = right - left
    height = top - bottom

    dx = (dx_percent / 100.0) * width
    dy = (dy_percent / 100.0) * height

    if corner == "top-left":
        return (left + dx, top - dy)
    elif corner == "top-right":
        return (right - dx, top - dy)
    elif corner == "bottom-left":
        return (left + dx, bottom + dy)
    elif corner == "bottom-right":
        return (right - dx, bottom + dy)
    else:
        raise ValueError("Invalid corner. Choose from: 'top-left', 'top-right', 'bottom-left', 'bottom-right'.")


if __name__ == "__main__":

    # === FEMM Setup ===
    femm.openfemm()  # Launch FEMM application
    femm.newdocument(1)  # 1 = Electrostatics (1 = electrostatics, 0 = magnetics)
    femm.ei_probdef('centimeters', 'planar', 1e-8, 7, 30)
    
    # === Draw Geometry ===

    # parameters for the model
    TxD = 20      # TxD: Distance from Tx to Rx (was TxRxDist)
    TxW = 3       # TxW: Tx/Rx Electrode Width
    TxG = 3       # TxG: Tx/Rx Electrode Gap (was TxGap)
    RxH = 30      # RxH: Rx Height
    RxA = -10     # RxA: Rx Anchor Y
    RxT = 0.2     # RxT: Rx Electrode Thickness
    TxT = 0.2     # TxT: Tx Electrode Thickness

    # define rectangle geometries for the model and boundary    
    rectangles = {
        "Head": (-12.5, 19.4, -1.5, 8.5),        # Top extended to y = 8.5
        "Body": (-14, 8.4, 0, -38.9),            # Detached from Head (gap between 8.5 and 8.4)
        "Leg": (-12, -39.0, -2, -109),           # Detached from Body (gap between -38.9 and -39.0)
            
        "Skin-Bottom":   (0, 0.000, 70, 0.063),
        "Fat-Lower":     (0, 0.063, 70, 0.520),
        "Muscle-Lower":  (0, 0.520, 70, 1.775),
        "Bone-Lower":    (0, 1.775, 70, 2.127),
        "Bone-Marrow":   (0, 2.127, 70, 2.500),
        "Bone-Upper":    (0, 2.500, 70, 2.852),
        "Muscle-Upper":  (0, 2.852, 70, 4.107),
        "Fat-Upper":     (0, 4.107, 70, 4.564),
        "Skin-Top":      (0, 4.564, 70, 4.627),    
        
        "Tx-Signal": (70-TxD-TxW,4.627+TxT, 70-TxD,4.627),
        "Tx-Ground": (70-TxD-2*TxW-TxG,4.627+TxT,70-TxD-TxW-TxG,4.627),        
        
        "Rx-Signal": (55, 0, 70, 0-RxT),
        "Rx-Gnd": (55, RxA, 55-RxT, RxA - RxH),    

        "Wood": (55, 0-RxT, 90, -109),

        #"Outer": (-40, -135, 115, 30)
        "Outer": (-610, 610, 610, -610)# 5 times to model safe boundary box
        #"Outer": (-1280, 1280, 1280, -1280)
    }
    # draw the rectangle geometries 
    for coords in rectangles.values():
        femm.ei_drawrectangle(*coords)

    # === Boundary Definition ===
    femm.ei_addboundprop('Ground', 0, 0, 0, 0, 0)  # (name, V, q, c0, c1, c2)
    assign_segments(boundary='Ground', points=get_rectangle_edges(*rectangles["Outer"]))

    # === Define Materials ===
    femm.ei_addmaterial('Air', 1, 1, 0)
    femm.ei_addmaterial('Skin', 2.0e4, 1, 0)
    femm.ei_addmaterial('Fat', 1.0e2, 1, 0)
    femm.ei_addmaterial('Muscle', 8.0e3, 1, 0)
    femm.ei_addmaterial('Bone', 2.5e2, 1, 0)
    femm.ei_addmaterial('Bone-Marrow', 2.5e2, 1, 0)
    femm.ei_addmaterial('Wood', 2.0, 1, 0)

    # === Assign Regions to Materials ===
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
        "Wood": "Wood"
    }
    # Assign conductors (no mesh for conductors)
    for name in conductor_regions:
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), '<No Mesh>')
    # Assign materials for tissue/wood/air
    for name, mat in material_map.items():
        if name in rectangles:
            label_block(*get_rectangle_center(*rectangles[name]), mat)
    
  
  
    label_block(*get_rectangle_topleft(*rectangles["Outer"]), 'Air')   # Air region outside the plates

    # === Define Conductors/Electrodes ===
    femm.ei_addconductorprop('eTx-Signal', 5, 0, 1)     # 1V
    femm.ei_addconductorprop('eTx-Ground', 0, 0, 1)    # 0V
    femm.ei_addconductorprop('eRx-Signal', 0, 0, 0)    # Floating
    femm.ei_addconductorprop('eRx-Gnd', 0, 0, 0)       # Floating
    femm.ei_addconductorprop('eHead', 0, 0, 0)         # Floating
    femm.ei_addconductorprop('eBody', 0, 0, 0)         # Floating
    femm.ei_addconductorprop('eLeg', 0, 0, 0)          # Floating

    # === Assign Segments to Conductors ===
    assign_segments(conductor='eTx-Ground', points=get_rectangle_edges(*rectangles["Tx-Ground"]))
    assign_segments(conductor='eTx-Signal', points=get_rectangle_edges(*rectangles["Tx-Signal"]))
    assign_segments(conductor='eRx-Gnd', points=get_rectangle_edges(*rectangles["Rx-Gnd"]))
    assign_segments(conductor='eRx-Signal', points=get_rectangle_edges(*rectangles["Rx-Signal"]))
    assign_segments(conductor='eHead', points=get_rectangle_edges(*rectangles["Head"]))
    assign_segments(conductor='eBody', points=get_rectangle_edges(*rectangles["Body"]))
    assign_segments(conductor='eLeg', points=get_rectangle_edges(*rectangles["Leg"]))

    # === Solve and Output ===
    femm.ei_saveas('hbc.fee')  # (filename)
    femm.ei_analyze(1)  # Run analysis
    femm.ei_loadsolution()  # Load solution
    
    # Save the model as a bitmap image
    femm.ei_zoomnatural()  # Zoom to fit the model
    femm.ei_savebitmap('hbc.bmp')  # Save model view as BMP

    # Voltage for Rx electrodes
    v_rx_signal = femm.eo_getconductorproperties('eRx-Signal')[0]  # [0] is voltage
    v_rx_gnd = femm.eo_getconductorproperties('eRx-Gnd')[0]       # [0] is voltage    
    v_diff_rx = v_rx_signal - v_rx_gnd
    print(f"Voltage difference between Rx electrodes = {v_diff_rx:.4f} V")

   # femm.closefemm() 