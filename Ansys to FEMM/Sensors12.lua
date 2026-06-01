-- FEMM 4.2 Script for Galvanic HBC - Full Human Body Model
-- Based on: Song et al. 2012 (sensors-12-13567.pdf)
-- Creates 2D planar cross-section showing both sides of body

showconsole()
print("========================================")
print("Galvanic HBC - Full Human Body Model")
print("Based on Song et al. Sensors 2012")
print("========================================")

-- 1. Create New Electrostatic Problem
newdocument(1)

-- 2. Define Problem - PLANAR (not axisymmetric) to show both sides
ei_probdef("millimeters", "planar", 1e-8, 0, 30)

-- 3. Simulation Parameters
local frequency = 400 -- kHz
print("Frequency: " .. frequency .. " kHz")

-- 4. Define Materials (Table 1, f=400kHz)
ei_addmaterial("Skin", 8000, 8000, 0, 0, 0.13, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Fat", 40, 40, 0, 0, 0.045, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Muscle", 4000, 4000, 0, 0, 0.50, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Bone", 200, 200, 0, 0, 0.025, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Air", 1, 1, 0, 0, 1e-12, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Copper", 1, 1, 0, 0, 5.96e7, 0, 0, 0, 0, 0, 0)

print("Materials defined")

-- 5. Helper function - create symmetric body segment with 4 layers
function create_segment_symmetric(y_bot, y_top, r_outer, t_skin, t_fat, t_muscle, r_bone, segment_name)
    -- Calculate radii for right side
    local r_skin = r_outer
    local r_fat = r_skin - t_skin
    local r_muscle = r_fat - t_fat
    local r_muscle_inner = r_muscle - t_muscle
    local r_bone_outer = r_bone or r_muscle_inner
    
    -- RIGHT SIDE - Draw vertical lines at each radius
    -- Bone boundary
    if r_bone_outer > 0 then
        ei_addnode(r_bone_outer, y_bot)
        ei_addnode(r_bone_outer, y_top)
        ei_addsegment(r_bone_outer, y_bot, r_bone_outer, y_top)
    end
    
    -- Muscle boundary
    ei_addnode(r_muscle, y_bot)
    ei_addnode(r_muscle, y_top)
    ei_addsegment(r_muscle, y_bot, r_muscle, y_top)
    
    -- Fat boundary
    ei_addnode(r_fat, y_bot)
    ei_addnode(r_fat, y_top)
    ei_addsegment(r_fat, y_bot, r_fat, y_top)
    
    -- Skin (outer) boundary
    ei_addnode(r_skin, y_bot)
    ei_addnode(r_skin, y_top)
    ei_addsegment(r_skin, y_bot, r_skin, y_top)
    
    -- LEFT SIDE (mirror) - Draw vertical lines at negative radii
    -- Bone boundary
    if r_bone_outer > 0 then
        ei_addnode(-r_bone_outer, y_bot)
        ei_addnode(-r_bone_outer, y_top)
        ei_addsegment(-r_bone_outer, y_bot, -r_bone_outer, y_top)
    end
    
    -- Muscle boundary
    ei_addnode(-r_muscle, y_bot)
    ei_addnode(-r_muscle, y_top)
    ei_addsegment(-r_muscle, y_bot, -r_muscle, y_top)
    
    -- Fat boundary
    ei_addnode(-r_fat, y_bot)
    ei_addnode(-r_fat, y_top)
    ei_addsegment(-r_fat, y_bot, -r_fat, y_top)
    
    -- Skin (outer) boundary
    ei_addnode(-r_skin, y_bot)
    ei_addnode(-r_skin, y_top)
    ei_addsegment(-r_skin, y_bot, -r_skin, y_top)
    
    -- Draw horizontal lines at top and bottom connecting both sides
    ei_addsegment(-r_skin, y_bot, r_skin, y_bot)
    ei_addsegment(-r_skin, y_top, r_skin, y_top)
    
    -- Add block labels at midpoint for RIGHT side
    local y_mid = (y_bot + y_top) / 2
    
    -- Bone (right)
    if r_bone_outer > 0 then
        ei_addblocklabel(r_bone_outer / 2, y_mid)
        ei_selectlabel(r_bone_outer / 2, y_mid)
        ei_setblockprop("Bone", 1, 0, 0)
        ei_clearselected()
        
        -- Bone (left)
        ei_addblocklabel(-r_bone_outer / 2, y_mid)
        ei_selectlabel(-r_bone_outer / 2, y_mid)
        ei_setblockprop("Bone", 1, 0, 0)
        ei_clearselected()
    end
    
    -- Muscle (right)
    ei_addblocklabel((r_bone_outer + r_muscle) / 2, y_mid)
    ei_selectlabel((r_bone_outer + r_muscle) / 2, y_mid)
    ei_setblockprop("Muscle", 1, 0, 0)
    ei_clearselected()
    
    -- Muscle (left)
    ei_addblocklabel(-(r_bone_outer + r_muscle) / 2, y_mid)
    ei_selectlabel(-(r_bone_outer + r_muscle) / 2, y_mid)
    ei_setblockprop("Muscle", 1, 0, 0)
    ei_clearselected()
    
    -- Fat (right)
    ei_addblocklabel((r_muscle + r_fat) / 2, y_mid)
    ei_selectlabel((r_muscle + r_fat) / 2, y_mid)
    ei_setblockprop("Fat", 1, 0, 0)
    ei_clearselected()
    
    -- Fat (left)
    ei_addblocklabel(-(r_muscle + r_fat) / 2, y_mid)
    ei_selectlabel(-(r_muscle + r_fat) / 2, y_mid)
    ei_setblockprop("Fat", 1, 0, 0)
    ei_clearselected()
    
    -- Skin (right)
    ei_addblocklabel((r_fat + r_skin) / 2, y_mid)
    ei_selectlabel((r_fat + r_skin) / 2, y_mid)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
    
    -- Skin (left)
    ei_addblocklabel(-(r_fat + r_skin) / 2, y_mid)
    ei_selectlabel(-(r_fat + r_skin) / 2, y_mid)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
    
    print(segment_name .. ": y=" .. y_bot .. " to " .. y_top .. "mm, width=" .. (2*r_skin) .. "mm")
end

-- 6. Build body from bottom to top (Paper Section 2.2)

print("\nBuilding body segments...")

local y = 0

-- LEG - Shank (average radius for simplicity)
-- Paper: cone 79mm→30mm, length 360mm; Layers: 2,17,46,14mm
local leg_shank_r_avg = (79 + 30) / 2  -- ≈ 54.5mm
create_segment_symmetric(y, y + 360, leg_shank_r_avg, 2, 17, 30, 14, "Leg-Shank")
y = y + 360

-- LEG - Thigh 
-- Paper: cylinder 79mm radius, 470mm; Layers: 2,17,46,14mm
create_segment_symmetric(y, y + 470, 79, 2, 17, 46, 14, "Leg-Thigh")
y = y + 470

-- TORSO
-- Paper: elliptic cylinder 590mm, avg radius ~115mm; Layers: 1.7,22,27,bone~60mm
create_segment_symmetric(y, y + 590, 115, 1.7, 22, 27, 60, "Torso")
local torso_mid_y = y + 295  -- Middle of torso for RX electrodes
y = y + 590

-- ARM reference height (for TX electrodes)
local arm_y = y - 320  -- 320mm from top of torso

-- NECK
-- Paper: cone 60mm height; Using average radius ~60mm
create_segment_symmetric(y, y + 60, 60, 2, 17, 17, 23, "Neck")
y = y + 60

-- HEAD
-- Paper: semi-sphere + cylinder, radius 80mm, total 210mm; Layers: 2,3,4,71mm
create_segment_symmetric(y, y + 210, 80, 2, 3, 4, 71, "Head")
y = y + 210

print("\nTotal body height: " .. y .. "mm")

-- 7. Add Electrodes on RIGHT SIDE

-- TRANSMITTER on ARM (A1 position) - RIGHT SIDE
local tx_r = 96.7  -- Upper arm outer radius
local tx_y = arm_y
local electrode_sep = 50

print("\n--- Adding Electrodes ---")

-- TX Electrode 1 (+) on RIGHT side
local tx1_y = tx_y - electrode_sep/2
ei_addnode(tx_r, tx1_y - 10)
ei_addnode(tx_r, tx1_y + 10)
ei_addnode(tx_r + 2, tx1_y - 10)
ei_addnode(tx_r + 2, tx1_y + 10)
ei_addsegment(tx_r, tx1_y - 10, tx_r, tx1_y + 10)
ei_addsegment(tx_r + 2, tx1_y - 10, tx_r + 2, tx1_y + 10)
ei_addsegment(tx_r, tx1_y - 10, tx_r + 2, tx1_y - 10)
ei_addsegment(tx_r, tx1_y + 10, tx_r + 2, tx1_y + 10)
ei_addblocklabel(tx_r + 1, tx1_y)
ei_selectlabel(tx_r + 1, tx1_y)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

-- TX Electrode 2 (-) on RIGHT side
local tx2_y = tx_y + electrode_sep/2
ei_addnode(tx_r, tx2_y - 10)
ei_addnode(tx_r, tx2_y + 10)
ei_addnode(tx_r + 2, tx2_y - 10)
ei_addnode(tx_r + 2, tx2_y + 10)
ei_addsegment(tx_r, tx2_y - 10, tx_r, tx2_y + 10)
ei_addsegment(tx_r + 2, tx2_y - 10, tx_r + 2, tx2_y + 10)
ei_addsegment(tx_r, tx2_y - 10, tx_r + 2, tx2_y - 10)
ei_addsegment(tx_r, tx2_y + 10, tx_r + 2, tx2_y + 10)
ei_addblocklabel(tx_r + 1, tx2_y)
ei_selectlabel(tx_r + 1, tx2_y)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

print("TX electrodes on right arm: x=" .. tx_r .. "mm, y=" .. tx_y .. "mm")

-- RECEIVER on TORSO (T2 position) - RIGHT SIDE
local rx_r = 115  -- Torso outer radius
local rx_y = torso_mid_y

-- RX Electrode 1 (+) on RIGHT side
local rx1_y = rx_y - electrode_sep/2
ei_addnode(rx_r, rx1_y - 10)
ei_addnode(rx_r, rx1_y + 10)
ei_addnode(rx_r + 2, rx1_y - 10)
ei_addnode(rx_r + 2, rx1_y + 10)
ei_addsegment(rx_r, rx1_y - 10, rx_r, rx1_y + 10)
ei_addsegment(rx_r + 2, rx1_y - 10, rx_r + 2, rx1_y + 10)
ei_addsegment(rx_r, rx1_y - 10, rx_r + 2, rx1_y - 10)
ei_addsegment(rx_r, rx1_y + 10, rx_r + 2, rx1_y + 10)
ei_addblocklabel(rx_r + 1, rx1_y)
ei_selectlabel(rx_r + 1, rx1_y)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

-- RX Electrode 2 (-) on RIGHT side
local rx2_y = rx_y + electrode_sep/2
ei_addnode(rx_r, rx2_y - 10)
ei_addnode(rx_r, rx2_y + 10)
ei_addnode(rx_r + 2, rx2_y - 10)
ei_addnode(rx_r + 2, rx2_y + 10)
ei_addsegment(rx_r, rx2_y - 10, rx_r, rx2_y + 10)
ei_addsegment(rx_r + 2, rx2_y - 10, rx_r + 2, rx2_y + 10)
ei_addsegment(rx_r, rx2_y - 10, rx_r + 2, rx2_y - 10)
ei_addsegment(rx_r, rx2_y + 10, rx_r + 2, rx2_y + 10)
ei_addblocklabel(rx_r + 1, rx2_y)
ei_selectlabel(rx_r + 1, rx2_y)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

print("RX electrodes on torso: x=" .. rx_r .. "mm, y=" .. rx_y .. "mm")

-- 8. Air region (surrounding the body)
local air_margin = 150
local air_left = -200
local air_right = 200
local air_bottom = -50
local air_top = y + 50

-- Draw air boundary rectangle
ei_addnode(air_left, air_bottom)
ei_addnode(air_right, air_bottom)
ei_addnode(air_right, air_top)
ei_addnode(air_left, air_top)

ei_addsegment(air_left, air_bottom, air_right, air_bottom)
ei_addsegment(air_right, air_bottom, air_right, air_top)
ei_addsegment(air_right, air_top, air_left, air_top)
ei_addsegment(air_left, air_top, air_left, air_bottom)

-- Label air regions (left and right of body)
ei_addblocklabel(air_left + 20, y/2)
ei_selectlabel(air_left + 20, y/2)
ei_setblockprop("Air", 1, 0, 0)
ei_clearselected()

ei_addblocklabel(air_right - 20, y/2)
ei_selectlabel(air_right - 20, y/2)
ei_setblockprop("Air", 1, 0, 0)
ei_clearselected()

print("Air region added")

-- 9. Boundary Conditions
ei_addboundprop("Ground", 0, 0, 0, 0, 0, 0)

-- Apply to outer air boundary
ei_selectsegment((air_left + air_right)/2, air_bottom)
ei_setsegmentprop("Ground", 0, 1, 0, 0, "<None>")
ei_clearselected()

ei_selectsegment((air_left + air_right)/2, air_top)
ei_setsegmentprop("Ground", 0, 1, 0, 0, "<None>")
ei_clearselected()

ei_selectsegment(air_left, (air_bottom + air_top)/2)
ei_setsegmentprop("Ground", 0, 1, 0, 0, "<None>")
ei_clearselected()

ei_selectsegment(air_right, (air_bottom + air_top)/2)
ei_setsegmentprop("Ground", 0, 1, 0, 0, "<None>")
ei_clearselected()

-- 10. Define Conductors
ei_addconductorprop("Tx-Positive", 1, 0, 1)
ei_addconductorprop("Tx-Negative", 0, 0, 1)
ei_addconductorprop("Rx-Positive", 0, 0, 0)
ei_addconductorprop("Rx-Negative", 0, 0, 0)

-- Assign conductors to electrodes
ei_selectsegment(tx_r, tx1_y)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Tx-Positive")
ei_clearselected()

ei_selectsegment(tx_r, tx2_y)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Tx-Negative")
ei_clearselected()

ei_selectsegment(rx_r, rx1_y)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Rx-Positive")
ei_clearselected()

ei_selectsegment(rx_r, rx2_y)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Rx-Negative")
ei_clearselected()

print("Conductors assigned")

-- 11. Save
ei_zoomnatural()
ei_saveas("Galvanic_HBC_Symmetric.fee")

print("\n========================================")
print("MODEL COMPLETE - SYMMETRIC!")
print("========================================")
print("\nBody structure (front view):")
print("       ___")
print("      |   |  Head")
print("       | |   Neck")
print("   _____|_____|_____")
print("  |              |  Torso (RX here)")
print("  |______________|")
print("       | |")
print("       | |  Thigh (TX at top)")
print("       | |")
print("       | |  Shank")
print("       | |")
print("\n✓ Both sides visible with all 4 layers")
print("✓ Skin/Fat/Muscle/Bone clearly defined")
print("✓ Electrodes on right side of body")
print("\nPath: Arm(A1) → Torso(T2)")
print("Frequency: " .. frequency .. " kHz")
print("========================================")

-- Solve
local response = messagebox("Symmetric model created!\n\nShows both sides of body\nArm→Torso configuration\n\nSolve now?", "Ready", 4)
if response == 6 then
    print("\nMeshing...")
    ei_createmesh()
    print("Solving...")
    ei_analyze(1)
    print("Loading solution...")
    ei_loadsolution()
    
    local props_rx_pos = eo_getconductorproperties("Rx-Positive")
    local props_rx_neg = eo_getconductorproperties("Rx-Negative")
    
    if props_rx_pos and props_rx_neg then
        local v_rx_pos = props_rx_pos[1]
        local v_rx_neg = props_rx_neg[1]
        local v_diff = v_rx_pos - v_rx_neg
        local atten_db = 20 * math.log10(math.abs(v_diff))
        
        print("\n========================================")
        print("RESULTS")
        print("========================================")
        print(string.format("V_Tx = 1.0 V (differential)"))
        print(string.format("V_Rx(+) = %.6f V", v_rx_pos))
        print(string.format("V_Rx(-) = %.6f V", v_rx_neg))
        print(string.format("V_Rx = %.6f V (differential)", v_diff))
        print(string.format("Attenuation = %.2f dB", atten_db))
        print("========================================")
        print("\nCompare with Figure 9(b) A1→T2:")
        print("Expected: -30 to -25 dB @ 400kHz")
        print("========================================")
    end
end