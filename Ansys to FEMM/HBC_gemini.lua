-- FEMM 4.2 LUA Script: Galvanic Coupling (Upper Arm Model)
-- Based on Sensors 2012, 12, 13567-13582
-- Implements geometry from Section 2.2 and Materials from Table 1

showconsole()
print("Generating 2D Axisymmetric Model of the Upper Arm...")

-- 1. Create New Current Flow Problem (Type 3)
-- The paper neglects inductive effects (quasi-static), so we use Current Flow.
newdocument(3) 

-- 2. Define Problem Parameters
-- Units: Millimeters
-- Type: Axisymmetric (Simulates a 3D cylinder)
-- Frequency: 0 (DC/Quasi-static approximation for conductivity)
ci_probdef("millimeters", "axi", 0, 1e-8, 30)

-- 3. Define Dimensions (From Paper Section 2.2, Page 5)
-- The paper models the upper arm as a cylinder with 4 layers.
-- Thicknesses[cite: 114]:
-- Skin: 1.7 mm
-- Fat: 12 mm
-- Muscle: 23 mm
-- Bone (Radius): 60 mm

local t_skin = 1.7
local t_fat = 12
local t_muscle = 23
local r_bone = 60

-- Calculate cumulative radii (Distance from center axis)
local r1 = r_bone                      -- Interface Bone/Muscle (60mm)
local r2 = r_bone + t_muscle           -- Interface Muscle/Fat (83mm)
local r3 = r2 + t_fat                  -- Interface Fat/Skin (95mm)
local r4 = r3 + t_skin                 -- Outer Surface (96.7mm)

local arm_length = 300 -- Arbitrary length sufficient to show attenuation (Paper uses 32mm segments, simplified here to a long section)

-- 4. Define Materials (From Paper Table 1, Page 6)
-- NOTE: Values below are for 100 kHz (Sample frequency).
-- You must update these values for different frequencies based on Table 1.
-- Format: ci_addmaterial("Name", sigma_x, sigma_y, 0, 0)

-- Bone  (approx 2.0E-02 S/m)
ci_addmaterial("Cortical_Bone", 0.02, 0.02, 0, 0)

-- Muscle  (100kHz approx 4.0E-02 S/m)
ci_addmaterial("Muscle", 0.04, 0.04, 0, 0)

-- Fat  (100kHz approx 2.8E-02 S/m)
ci_addmaterial("Fat", 0.028, 0.028, 0, 0)

-- Skin  (100kHz approx 3.9E-01 S/m)
-- Note: Skin conductivity varies drastically with frequency.
ci_addmaterial("Skin", 0.39, 0.39, 0, 0)

-- Copper Electrodes [cite: 138]
ci_addmaterial("Copper", 5.99e7, 5.99e7, 0, 0)
local elec_radius = 10 -- Paper specifies 10mm radius electrodes [cite: 138]

-- 5. Draw Geometry (Nested Rectangles for Layers)

-- Function to draw a layer rectangle and add a block label
function drawLayer(r_inner, r_outer, length, mat_name)
    -- Draw nodes
    ci_addnode(r_inner, 0)
    ci_addnode(r_outer, 0)
    ci_addnode(r_outer, length)
    ci_addnode(r_inner, length)
    
    -- Draw segments
    ci_addsegment(r_inner, 0, r_outer, 0)
    ci_addsegment(r_outer, 0, r_outer, length)
    ci_addsegment(r_outer, length, r_inner, length)
    ci_addsegment(r_inner, length, r_inner, 0)
    
    -- Place Block Label in the middle of the layer
    local mid_r = (r_inner + r_outer) / 2
    local mid_z = length / 2
    ci_addblocklabel(mid_r, mid_z)
    ci_selectlabel(mid_r, mid_z)
    ci_setblockprop(mat_name, 1, 0, 0) -- Automesh on
    ci_clearselected()
end

-- Draw Bone (Center Cylinder)
drawLayer(0, r1, arm_length, "Cortical_Bone")

-- Draw Muscle
drawLayer(r1, r2, arm_length, "Muscle")

-- Draw Fat
drawLayer(r2, r3, arm_length, "Fat")

-- Draw Skin
drawLayer(r3, r4, arm_length, "Skin")

-- 6. Add Electrodes (Transmitter)
-- Paper puts electrodes on the surface (Skin)
-- We simulate a ring electrode in Axisymmetric mode (approximate)
-- Location: 50mm from bottom edge
local elec_z_center = 50
local elec_width = 20 -- Diameter of electrode (2 * 10mm radius)

-- Draw Electrode on Surface
ci_addnode(r4, elec_z_center - elec_width/2)
ci_addnode(r4, elec_z_center + elec_width/2)
ci_addnode(r4 + 1, elec_z_center + elec_width/2) -- 1mm thick copper
ci_addnode(r4 + 1, elec_z_center - elec_width/2)

ci_addsegment(r4, elec_z_center - elec_width/2, r4 + 1, elec_z_center - elec_width/2)
ci_addsegment(r4 + 1, elec_z_center - elec_width/2, r4 + 1, elec_z_center + elec_width/2)
ci_addsegment(r4 + 1, elec_z_center + elec_width/2, r4, elec_z_center + elec_width/2)

-- Label Electrode
ci_addblocklabel(r4 + 0.5, elec_z_center)
ci_selectlabel(r4 + 0.5, elec_z_center)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

-- 7. Apply Boundary Conditions
-- The paper states: "Normal component of electric field... boundary between skin and air was set to zero" [cite: 137]
-- In FEMM, no defined boundary condition implies "Neumann" (d/dn = 0), which is exactly what is required.
-- So we do not add an "Asymptotic" or "Ground" boundary on the outside.

-- 8. Zoom to fit
ci_zoomnatural()

print("Geometry Generated. Layers: Bone (0-60mm), Muscle (60-83mm), Fat (83-95mm), Skin (95-96.7mm).")