-- FEMM 4.2 Script for Capacitive Human Body Communication Model
-- Based on: "BioPhysical Modeling, Characterization and Optimization of 
-- Electro-Quasistatic Human Body Communication" (Maity et al., 2018)
-- 2D Axisymmetric Cross-Section Model

showconsole()
print("========================================")
print("Generating Capacitive HBC Model (Arm Cross-Section)")
print("Based on Maity et al. 2018 paper")
print("========================================")

-- 1. Create New Current Flow Problem
newdocument(3) -- Current flow problem

-- 2. Define Problem Parameters
ci_probdef("millimeters", "planar", 0, 1e-8, 30)

-- 3. Frequency for simulation
local frequency = 100 -- kHz

print("Frequency: " .. frequency .. " kHz")
print("Model Type: Capacitive HBC")

-- 4. Define Materials
ci_addmaterial("Skin", 0.04, 0.04, 0, 0)        
ci_addmaterial("Fat", 0.028, 0.028, 0, 0)       
ci_addmaterial("Muscle", 0.39, 0.39, 0, 0)      
ci_addmaterial("Bone", 0.02, 0.02, 0, 0)        
ci_addmaterial("Copper", 5.99e7, 5.99e7, 0, 0)  
ci_addmaterial("Air", 1e-10, 1e-10, 0, 0)       

print("Materials defined")

-- 5. Define Arm Dimensions (Cross-section view)
-- Layer thicknesses
local t_skin = 2      -- mm
local t_fat = 5       -- mm
local t_muscle = 30   -- mm
local r_bone = 15     -- mm (bone radius)

-- Cumulative radii from center
local r1 = r_bone                    -- Bone
local r2 = r1 + t_muscle            -- Muscle
local r3 = r2 + t_fat               -- Fat
local r4 = r3 + t_skin              -- Skin (outer surface)

print("Arm cross-section radii:")
print("  Bone (0 to " .. r1 .. " mm)")
print("  Muscle (" .. r1 .. " to " .. r2 .. " mm)")
print("  Fat (" .. r2 .. " to " .. r3 .. " mm)")
print("  Skin (" .. r3 .. " to " .. r4 .. " mm)")

-- 6. Draw Concentric Circles for Body Layers
print("Drawing body layers as concentric circles...")

-- Helper function to draw a circle using 4 arcs (90 degrees each)
function drawCircle(cx, cy, radius)
    -- Draw circle as 4 quarter arcs
    -- Top point
    ci_addnode(cx, cy + radius)
    -- Right point
    ci_addnode(cx + radius, cy)
    -- Bottom point
    ci_addnode(cx, cy - radius)
    -- Left point
    ci_addnode(cx - radius, cy)
    
    -- Draw 4 arcs connecting the points
    ci_addarc(cx, cy + radius, cx + radius, cy, 90, 1)      -- Top to Right
    ci_addarc(cx + radius, cy, cx, cy - radius, 90, 1)      -- Right to Bottom
    ci_addarc(cx, cy - radius, cx - radius, cy, 90, 1)      -- Bottom to Left
    ci_addarc(cx - radius, cy, cx, cy + radius, 90, 1)      -- Left to Top
end

-- Body center position
local body_cx = 0
local body_cy = 150

-- Draw all layers
drawCircle(body_cx, body_cy, r1) -- Bone
drawCircle(body_cx, body_cy, r2) -- Muscle boundary
drawCircle(body_cx, body_cy, r3) -- Fat boundary  
drawCircle(body_cx, body_cy, r4) -- Skin boundary

-- Add block labels for each layer
ci_addblocklabel(body_cx, body_cy) -- Bone center
ci_selectlabel(body_cx, body_cy)
ci_setblockprop("Bone", 1, 0, 0)
ci_clearselected()

ci_addblocklabel(body_cx + (r1 + r2)/2, body_cy) -- Muscle
ci_selectlabel(body_cx + (r1 + r2)/2, body_cy)
ci_setblockprop("Muscle", 1, 0, 0)
ci_clearselected()

ci_addblocklabel(body_cx + (r2 + r3)/2, body_cy) -- Fat
ci_selectlabel(body_cx + (r2 + r3)/2, body_cy)
ci_setblockprop("Fat", 1, 0, 0)
ci_clearselected()

ci_addblocklabel(body_cx + (r3 + r4)/2, body_cy) -- Skin
ci_selectlabel(body_cx + (r3 + r4)/2, body_cy)
ci_setblockprop("Skin", 1, 0, 0)
ci_clearselected()

print("Body structure created")

-- 7. Add Transmitter Electrode (on skin surface)
-- Electrode specs: ~4 cm² area, positioned on top of arm
local elec_width = 15  -- mm (electrode width)
local elec_thickness = 1  -- mm

local tx_x = body_cx
local tx_y = body_cy + r4  -- On top of skin

print("Adding TRANSMITTER electrode...")

-- Draw TX electrode as rectangle on top
ci_addnode(tx_x - elec_width/2, tx_y)
ci_addnode(tx_x + elec_width/2, tx_y)
ci_addnode(tx_x + elec_width/2, tx_y + elec_thickness)
ci_addnode(tx_x - elec_width/2, tx_y + elec_thickness)

ci_addsegment(tx_x - elec_width/2, tx_y, tx_x + elec_width/2, tx_y)
ci_addsegment(tx_x + elec_width/2, tx_y, tx_x + elec_width/2, tx_y + elec_thickness)
ci_addsegment(tx_x + elec_width/2, tx_y + elec_thickness, tx_x - elec_width/2, tx_y + elec_thickness)
ci_addsegment(tx_x - elec_width/2, tx_y + elec_thickness, tx_x - elec_width/2, tx_y)

ci_addblocklabel(tx_x, tx_y + elec_thickness/2)
ci_selectlabel(tx_x, tx_y + elec_thickness/2)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

print("TX electrode at (" .. tx_x .. ", " .. tx_y .. ")")

-- 8. Add TX Ground Plane (nearby, for return path)
local tx_gnd_separation = 10  -- mm from electrode
local tx_gnd_y = tx_y + elec_thickness + tx_gnd_separation
local gnd_width = 20

ci_addnode(tx_x - gnd_width/2, tx_gnd_y)
ci_addnode(tx_x + gnd_width/2, tx_gnd_y)
ci_addnode(tx_x + gnd_width/2, tx_gnd_y + elec_thickness)
ci_addnode(tx_x - gnd_width/2, tx_gnd_y + elec_thickness)

ci_addsegment(tx_x - gnd_width/2, tx_gnd_y, tx_x + gnd_width/2, tx_gnd_y)
ci_addsegment(tx_x + gnd_width/2, tx_gnd_y, tx_x + gnd_width/2, tx_gnd_y + elec_thickness)
ci_addsegment(tx_x + gnd_width/2, tx_gnd_y + elec_thickness, tx_x - gnd_width/2, tx_gnd_y + elec_thickness)
ci_addsegment(tx_x - gnd_width/2, tx_gnd_y + elec_thickness, tx_x - gnd_width/2, tx_gnd_y)

ci_addblocklabel(tx_x, tx_gnd_y + elec_thickness/2)
ci_selectlabel(tx_x, tx_gnd_y + elec_thickness/2)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

print("TX ground plane added")

-- 9. Add Receiver Electrode (on side of arm, 90 degrees away)
local rx_x = body_cx + r4  -- On right side of skin
local rx_y = body_cy

print("Adding RECEIVER electrode...")

-- Draw RX electrode on side
ci_addnode(rx_x, rx_y - elec_width/2)
ci_addnode(rx_x + elec_thickness, rx_y - elec_width/2)
ci_addnode(rx_x + elec_thickness, rx_y + elec_width/2)
ci_addnode(rx_x, rx_y + elec_width/2)

ci_addsegment(rx_x, rx_y - elec_width/2, rx_x + elec_thickness, rx_y - elec_width/2)
ci_addsegment(rx_x + elec_thickness, rx_y - elec_width/2, rx_x + elec_thickness, rx_y + elec_width/2)
ci_addsegment(rx_x + elec_thickness, rx_y + elec_width/2, rx_x, rx_y + elec_width/2)
ci_addsegment(rx_x, rx_y + elec_width/2, rx_x, rx_y - elec_width/2)

ci_addblocklabel(rx_x + elec_thickness/2, rx_y)
ci_selectlabel(rx_x + elec_thickness/2, rx_y)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

print("RX electrode at (" .. rx_x .. ", " .. rx_y .. ")")

-- 10. Add RX Ground Plane
local rx_gnd_x = rx_x + elec_thickness + tx_gnd_separation

ci_addnode(rx_gnd_x, rx_y - gnd_width/2)
ci_addnode(rx_gnd_x + elec_thickness, rx_y - gnd_width/2)
ci_addnode(rx_gnd_x + elec_thickness, rx_y + gnd_width/2)
ci_addnode(rx_gnd_x, rx_y + gnd_width/2)

ci_addsegment(rx_gnd_x, rx_y - gnd_width/2, rx_gnd_x + elec_thickness, rx_y - gnd_width/2)
ci_addsegment(rx_gnd_x + elec_thickness, rx_y - gnd_width/2, rx_gnd_x + elec_thickness, rx_y + gnd_width/2)
ci_addsegment(rx_gnd_x + elec_thickness, rx_y + gnd_width/2, rx_gnd_x, rx_y + gnd_width/2)
ci_addsegment(rx_gnd_x, rx_y + gnd_width/2, rx_gnd_x, rx_y - gnd_width/2)

ci_addblocklabel(rx_gnd_x + elec_thickness/2, rx_y)
ci_selectlabel(rx_gnd_x + elec_thickness/2, rx_y)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

print("RX ground plane added")

-- 11. Add outer Air region
local air_radius = 200
drawCircle(body_cx, body_cy, air_radius)

ci_addblocklabel(body_cx + air_radius - 10, body_cy)
ci_selectlabel(body_cx + air_radius - 10, body_cy)
ci_setblockprop("Air", 1, 0, 0)
ci_clearselected()

print("Air region added")

-- 12. Define Boundary Conditions
ci_addboundprop("Voltage_TX", 1, 0, 0, 0)      -- 1V at TX
ci_addboundprop("Ground", 0, 0, 0, 0)          -- 0V at grounds
ci_addboundprop("Floating", 0, 0, 0, 0)        -- Floating RX

print("Boundary conditions defined")

-- Apply BC to TX electrode (top edge)
ci_selectsegment(tx_x, tx_y + elec_thickness)
ci_setsegmentprop("Voltage_TX", 0, 1, 0, 0)
ci_clearselected()

-- Apply ground to TX ground plane
ci_selectsegment(tx_x, tx_gnd_y + elec_thickness)
ci_setsegmentprop("Ground", 0, 1, 0, 0)
ci_clearselected()

-- Apply ground to RX ground plane
ci_selectsegment(rx_gnd_x + elec_thickness, rx_y)
ci_setsegmentprop("Ground", 0, 1, 0, 0)
ci_clearselected()

-- RX electrode floating
ci_selectsegment(rx_x + elec_thickness, rx_y)
ci_setsegmentprop("Floating", 0, 1, 0, 0)
ci_clearselected()

-- Outer boundary at ground
ci_selectarcsegment(body_cx + air_radius, body_cy)
ci_setarcsegmentprop(1, "Ground", 0, 0)
ci_clearselected()

print("Boundary conditions applied")

-- 13. Zoom to fit
ci_zoomnatural()

-- 14. Save
ci_saveas("Capacitive_HBC_CrossSection.fec")

print("========================================")
print("Model Complete - Cross-Section View")
print("========================================")
print("")
print("Visualization:")
print("  - Concentric circles = Body layers")
print("  - TX electrode on top of arm")
print("  - RX electrode on side of arm")
print("  - Ground planes for return path")
print("")
print("Model saved as: Capacitive_HBC_CrossSection.fec")
print("========================================")
print("")
print("Next Steps:")
print("1. Mesh: ci_createmesh()")
print("2. Solve: ci_analyze()")
print("3. View: ci_loadsolution()")
print("========================================")

-- Optional auto-solve
local response = messagebox("Cross-section model created!\n\nDo you want to mesh and solve?", "Solve", 4)
if response == 6 then
    print("Creating mesh...")
    ci_createmesh()
    print("Analyzing...")
    ci_analyze()
    print("Loading solution...")
    ci_loadsolution()
    print("Solution complete!")
end