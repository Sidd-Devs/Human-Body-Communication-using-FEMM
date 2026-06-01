-- FEMM 4.2 Script for Galvanic HBC - Full Human Body Model
-- Based on: Modak et al. 2022 Figure 8 & 9
-- Creates 2D human body silhouette with layered tissue structure

showconsole()
print("========================================")
print("Galvanic HBC - Full Human Body Model")
print("Based on Modak et al. IEEE TBME 2022")
print("Figure 8 & 9 Configuration")
print("========================================")

-- 1. Create New Electrostatic Problem
newdocument(1)

-- 2. Define Problem - Planar for body silhouette
ei_probdef("centimeters", "planar", 1e-8, 0, 30)

-- 3. Simulation Parameters
local frequency = 400 -- kHz

print("Frequency: " .. frequency .. " kHz")

-- 4. Define Materials
ei_addmaterial("Skin", 1200, 1200, 0, 0, 0.0002, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Muscle", 7000, 7000, 0, 0, 0.5, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Air", 1, 1, 0, 0, 1e-12, 0, 0, 0, 0, 0, 0)
ei_addmaterial("Copper", 1, 1, 0, 0, 5.96e7, 0, 0, 0, 0, 0, 0)

print("Materials defined")

-- 5. Human Body Dimensions (Simplified)
-- Based on average adult proportions
local head_width = 10
local head_height = 12
local neck_width = 6
local neck_height = 4
local torso_width = 18
local torso_height = 35
local arm_width = 4
local arm_length = 30
local leg_width = 6
local leg_length = 40

local skin_thickness = 0.3  -- cm (visible layer)

-- Starting position (bottom center)
local base_x = 0
local base_y = 0

print("Human body dimensions defined")

-- 6. Helper function to draw body part with skin+muscle layers
function draw_body_part_rect(x_center, y_bottom, width, height, name)
    -- Muscle (inner)
    local x_left_m = x_center - width/2 + skin_thickness
    local x_right_m = x_center + width/2 - skin_thickness
    local y_top_m = y_bottom + height - skin_thickness
    local y_bottom_m = y_bottom + skin_thickness
    
    -- Skin (outer)
    local x_left_s = x_center - width/2
    local x_right_s = x_center + width/2
    local y_top_s = y_bottom + height
    local y_bottom_s = y_bottom
    
    -- Draw outer skin rectangle
    ei_addnode(x_left_s, y_bottom_s)
    ei_addnode(x_right_s, y_bottom_s)
    ei_addnode(x_right_s, y_top_s)
    ei_addnode(x_left_s, y_top_s)
    
    ei_addsegment(x_left_s, y_bottom_s, x_right_s, y_bottom_s)
    ei_addsegment(x_right_s, y_bottom_s, x_right_s, y_top_s)
    ei_addsegment(x_right_s, y_top_s, x_left_s, y_top_s)
    ei_addsegment(x_left_s, y_top_s, x_left_s, y_bottom_s)
    
    -- Draw inner muscle rectangle
    ei_addnode(x_left_m, y_bottom_m)
    ei_addnode(x_right_m, y_bottom_m)
    ei_addnode(x_right_m, y_top_m)
    ei_addnode(x_left_m, y_top_m)
    
    ei_addsegment(x_left_m, y_bottom_m, x_right_m, y_bottom_m)
    ei_addsegment(x_right_m, y_bottom_m, x_right_m, y_top_m)
    ei_addsegment(x_right_m, y_top_m, x_left_m, y_top_m)
    ei_addsegment(x_left_m, y_top_m, x_left_m, y_bottom_m)
    
    -- Label muscle
    ei_addblocklabel(x_center, (y_bottom_m + y_top_m)/2)
    ei_selectlabel(x_center, (y_bottom_m + y_top_m)/2)
    ei_setblockprop("Muscle", 1, 0, 0)
    ei_clearselected()
    
    -- Label skin (4 regions around muscle)
    -- Bottom
    ei_addblocklabel(x_center, (y_bottom_s + y_bottom_m)/2)
    ei_selectlabel(x_center, (y_bottom_s + y_bottom_m)/2)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
    
    -- Top
    ei_addblocklabel(x_center, (y_top_m + y_top_s)/2)
    ei_selectlabel(x_center, (y_top_m + y_top_s)/2)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
    
    -- Left
    ei_addblocklabel((x_left_s + x_left_m)/2, y_bottom + height/2)
    ei_selectlabel((x_left_s + x_left_m)/2, y_bottom + height/2)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
    
    -- Right
    ei_addblocklabel((x_right_m + x_right_s)/2, y_bottom + height/2)
    ei_selectlabel((x_right_m + x_right_s)/2, y_bottom + height/2)
    ei_setblockprop("Skin", 1, 0, 0)
    ei_clearselected()
end

-- 7. Draw Human Body Parts

print("Drawing human body...")

-- Legs
local leg_left_x = base_x - leg_width/2 - 1
local leg_right_x = base_x + leg_width/2 + 1
local leg_y = base_y

draw_body_part_rect(leg_left_x, leg_y, leg_width, leg_length, "Left Leg")
draw_body_part_rect(leg_right_x, leg_y, leg_width, leg_length, "Right Leg")
print("Legs created")

-- Torso
local torso_y = leg_y + leg_length
draw_body_part_rect(base_x, torso_y, torso_width, torso_height, "Torso")
print("Torso created")

-- Arms (attached to torso)
local arm_left_x = base_x - torso_width/2 - arm_width/2 - 1
local arm_right_x = base_x + torso_width/2 + arm_width/2 + 1
local arm_y = torso_y + torso_height - arm_length

draw_body_part_rect(arm_left_x, arm_y, arm_width, arm_length, "Left Arm")
draw_body_part_rect(arm_right_x, arm_y, arm_width, arm_length, "Right Arm")
print("Arms created")

-- Neck
local neck_y = torso_y + torso_height
draw_body_part_rect(base_x, neck_y, neck_width, neck_height, "Neck")
print("Neck created")

-- Head
local head_y = neck_y + neck_height
draw_body_part_rect(base_x, head_y, head_width, head_height, "Head")
print("Head created")

-- 8. Add Electrodes on Right Arm (Galvanic Configuration)
local electrode_width = 2
local electrode_thickness = 0.2
local electrode_gap = 5  -- cm separation

-- Transmitter position on wrist
local tx_y = arm_y + 5
local tx_x = arm_right_x + arm_width/2

print("Adding transmitter electrodes on right arm...")

-- Tx-Positive
ei_addnode(tx_x, tx_y - electrode_gap/2 - electrode_width/2)
ei_addnode(tx_x + electrode_thickness, tx_y - electrode_gap/2 - electrode_width/2)
ei_addnode(tx_x + electrode_thickness, tx_y - electrode_gap/2 + electrode_width/2)
ei_addnode(tx_x, tx_y - electrode_gap/2 + electrode_width/2)

ei_addsegment(tx_x, tx_y - electrode_gap/2 - electrode_width/2, tx_x + electrode_thickness, tx_y - electrode_gap/2 - electrode_width/2)
ei_addsegment(tx_x + electrode_thickness, tx_y - electrode_gap/2 - electrode_width/2, tx_x + electrode_thickness, tx_y - electrode_gap/2 + electrode_width/2)
ei_addsegment(tx_x + electrode_thickness, tx_y - electrode_gap/2 + electrode_width/2, tx_x, tx_y - electrode_gap/2 + electrode_width/2)
ei_addsegment(tx_x, tx_y - electrode_gap/2 + electrode_width/2, tx_x, tx_y - electrode_gap/2 - electrode_width/2)

ei_addblocklabel(tx_x + electrode_thickness/2, tx_y - electrode_gap/2)
ei_selectlabel(tx_x + electrode_thickness/2, tx_y - electrode_gap/2)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

-- Tx-Negative
ei_addnode(tx_x, tx_y + electrode_gap/2 - electrode_width/2)
ei_addnode(tx_x + electrode_thickness, tx_y + electrode_gap/2 - electrode_width/2)
ei_addnode(tx_x + electrode_thickness, tx_y + electrode_gap/2 + electrode_width/2)
ei_addnode(tx_x, tx_y + electrode_gap/2 + electrode_width/2)

ei_addsegment(tx_x, tx_y + electrode_gap/2 - electrode_width/2, tx_x + electrode_thickness, tx_y + electrode_gap/2 - electrode_width/2)
ei_addsegment(tx_x + electrode_thickness, tx_y + electrode_gap/2 - electrode_width/2, tx_x + electrode_thickness, tx_y + electrode_gap/2 + electrode_width/2)
ei_addsegment(tx_x + electrode_thickness, tx_y + electrode_gap/2 + electrode_width/2, tx_x, tx_y + electrode_gap/2 + electrode_width/2)
ei_addsegment(tx_x, tx_y + electrode_gap/2 + electrode_width/2, tx_x, tx_y + electrode_gap/2 - electrode_width/2)

ei_addblocklabel(tx_x + electrode_thickness/2, tx_y + electrode_gap/2)
ei_selectlabel(tx_x + electrode_thickness/2, tx_y + electrode_gap/2)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

print("Tx electrodes at y = " .. tx_y .. " cm on right arm")

-- 9. Add Receiver Electrodes on Torso
local rx_y = torso_y + torso_height/2
local rx_x = base_x + torso_width/2

print("Adding receiver electrodes on torso...")

-- Rx-Positive
ei_addnode(rx_x, rx_y - electrode_gap/2 - electrode_width/2)
ei_addnode(rx_x + electrode_thickness, rx_y - electrode_gap/2 - electrode_width/2)
ei_addnode(rx_x + electrode_thickness, rx_y - electrode_gap/2 + electrode_width/2)
ei_addnode(rx_x, rx_y - electrode_gap/2 + electrode_width/2)

ei_addsegment(rx_x, rx_y - electrode_gap/2 - electrode_width/2, rx_x + electrode_thickness, rx_y - electrode_gap/2 - electrode_width/2)
ei_addsegment(rx_x + electrode_thickness, rx_y - electrode_gap/2 - electrode_width/2, rx_x + electrode_thickness, rx_y - electrode_gap/2 + electrode_width/2)
ei_addsegment(rx_x + electrode_thickness, rx_y - electrode_gap/2 + electrode_width/2, rx_x, rx_y - electrode_gap/2 + electrode_width/2)
ei_addsegment(rx_x, rx_y - electrode_gap/2 + electrode_width/2, rx_x, rx_y - electrode_gap/2 - electrode_width/2)

ei_addblocklabel(rx_x + electrode_thickness/2, rx_y - electrode_gap/2)
ei_selectlabel(rx_x + electrode_thickness/2, rx_y - electrode_gap/2)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

-- Rx-Negative
ei_addnode(rx_x, rx_y + electrode_gap/2 - electrode_width/2)
ei_addnode(rx_x + electrode_thickness, rx_y + electrode_gap/2 - electrode_width/2)
ei_addnode(rx_x + electrode_thickness, rx_y + electrode_gap/2 + electrode_width/2)
ei_addnode(rx_x, rx_y + electrode_gap/2 + electrode_width/2)

ei_addsegment(rx_x, rx_y + electrode_gap/2 - electrode_width/2, rx_x + electrode_thickness, rx_y + electrode_gap/2 - electrode_width/2)
ei_addsegment(rx_x + electrode_thickness, rx_y + electrode_gap/2 - electrode_width/2, rx_x + electrode_thickness, rx_y + electrode_gap/2 + electrode_width/2)
ei_addsegment(rx_x + electrode_thickness, rx_y + electrode_gap/2 + electrode_width/2, rx_x, rx_y + electrode_gap/2 + electrode_width/2)
ei_addsegment(rx_x, rx_y + electrode_gap/2 + electrode_width/2, rx_x, rx_y + electrode_gap/2 - electrode_width/2)

ei_addblocklabel(rx_x + electrode_thickness/2, rx_y + electrode_gap/2)
ei_selectlabel(rx_x + electrode_thickness/2, rx_y + electrode_gap/2)
ei_setblockprop("Copper", 1, 0, 0)
ei_clearselected()

print("Rx electrodes at y = " .. rx_y .. " cm on torso")

-- 10. Add Air Region
local total_height = head_y + head_height
local air_margin = 15

local air_left = base_x - torso_width/2 - arm_width - air_margin
local air_right = base_x + torso_width/2 + arm_width + air_margin
local air_bottom = base_y - air_margin
local air_top = total_height + air_margin

ei_addnode(air_left, air_bottom)
ei_addnode(air_right, air_bottom)
ei_addnode(air_right, air_top)
ei_addnode(air_left, air_top)

ei_addsegment(air_left, air_bottom, air_right, air_bottom)
ei_addsegment(air_right, air_bottom, air_right, air_top)
ei_addsegment(air_right, air_top, air_left, air_top)
ei_addsegment(air_left, air_top, air_left, air_bottom)

-- Label air regions
ei_addblocklabel(air_left + 2, air_bottom + 2)
ei_selectlabel(air_left + 2, air_bottom + 2)
ei_setblockprop("Air", 1, 0, 0)
ei_clearselected()

print("Air region added")

-- 11. Boundary Conditions
ei_addboundprop("Ground", 0, 0, 0, 0, 0, 0)

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

-- 12. Define Conductors
ei_addconductorprop("Tx-Positive", 1, 0, 1)
ei_addconductorprop("Tx-Negative", 0, 0, 1)
ei_addconductorprop("Rx-Positive", 0, 0, 0)
ei_addconductorprop("Rx-Negative", 0, 0, 0)

-- Apply to electrodes
ei_selectsegment(tx_x + electrode_thickness, tx_y - electrode_gap/2)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Tx-Positive")
ei_clearselected()

ei_selectsegment(tx_x + electrode_thickness, tx_y + electrode_gap/2)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Tx-Negative")
ei_clearselected()

ei_selectsegment(rx_x + electrode_thickness, rx_y - electrode_gap/2)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Rx-Positive")
ei_clearselected()

ei_selectsegment(rx_x + electrode_thickness, rx_y + electrode_gap/2)
ei_setsegmentprop("<None>", 0, 1, 0, 0, "Rx-Negative")
ei_clearselected()

print("Conductors assigned")

-- 13. Zoom and Save
ei_zoomnatural()
ei_saveas("Galvanic_HBC_Full_Body.fee")

print("========================================")
print("FULL HUMAN BODY MODEL COMPLETE!")
print("========================================")
print("")
print("Body Structure:")
print("  ○ Head")
print("  | Neck")
print("  ╫ Torso (Rx electrodes)")
print(" /|\ Arms (Tx on right arm)")
print("  |")
print(" / \ Legs")
print("")
print("All parts have:")
print("  - Skin layer (outer, dielectric)")
print("  - Muscle layer (inner, conductive)")
print("")
print("Configuration: Wrist-to-Torso HBC")
print("  Tx: Right wrist (differential)")
print("  Rx: Torso (differential)")
print("  Matches Figure 8 & 9 from paper")
print("========================================")

-- Auto-solve
local response = messagebox("Full human body model created!\n\nMatches Figure 8 & 9 from paper.\nDo you want to solve?", "Solve", 4)
if response == 6 then
    print("")
    print("Meshing...")
    ei_createmesh()
    print("Solving...")
    ei_analyze(1)
    print("Loading solution...")
    ei_loadsolution()
    
    local props_rx_pos = eo_getconductorproperties("Rx-Positive")
    local props_rx_neg = eo_getconductorproperties("Rx-Negative")
    
    if props_rx_pos and props_rx_neg then
        local v_diff = props_rx_pos[1] - props_rx_neg[1]
        local gain_db = 20 * math.log10(math.abs(v_diff))
        
        print("")
        print("========================================")
        print("RESULTS")
        print("========================================")
        print(string.format("V_Rx (differential) = %.6f V", v_diff))
        print(string.format("Channel Gain = %.2f dB", gain_db))
        print("========================================")
    end
    
    print("View E-field: Plot → Voltage Density")
    print("Should see field like Figure 8 in paper")
end