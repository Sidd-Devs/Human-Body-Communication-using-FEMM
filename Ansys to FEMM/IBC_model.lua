-- FEMM 4.2 Script for Galvanic Coupling Intra-Body Communication Model
-- Based on: "A Finite-Element Simulation of Galvanic Coupling Intra-Body Communication"
-- Sensors 2012, 12, 13567-13582
-- This creates a 2D axisymmetric model of the whole human body for IBC simulation

showconsole()
print("========================================")
print("Generating Whole Body IBC Model...")
print("========================================")

-- 1. Create New Current Flow Problem
newdocument(3) -- Current flow problem

-- 2. Define Problem Parameters
-- Units: millimeters, Axisymmetric, Frequency: 0 (quasi-static)
ci_probdef("millimeters", "axi", 0, 1e-8, 30)

-- 3. Frequency for simulation (you can change this)
local frequency = 100 -- kHz

print("Frequency: " .. frequency .. " kHz")

-- 4. Define Materials (From Table 1 in paper, for 100 kHz)
-- Format: ci_addmaterial("Name", sigma_x, sigma_y, qv, Kt)

-- Conductivity values for 100 kHz from Table 1
ci_addmaterial("Skin", 0.04, 0.04, 0, 0)
ci_addmaterial("Fat", 0.028, 0.028, 0, 0)
ci_addmaterial("Muscle", 0.39, 0.39, 0, 0)
ci_addmaterial("Bone", 0.02, 0.02, 0, 0)
ci_addmaterial("Copper", 5.99e7, 5.99e7, 0, 0)
ci_addmaterial("Air", 1e-10, 1e-10, 0, 0)

print("Materials defined")

-- 5. Define Body Part Dimensions (From paper Section 2.2)

-- HEAD dimensions (modeled as cylinder, from Figure 2)
local head_radius = 80 -- mm
local head_t_skin = 2
local head_t_fat = 3
local head_t_muscle = 4
local head_t_bone = 71 -- radius of bone

local head_r_bone = head_t_bone
local head_r_muscle = head_r_bone + head_t_muscle
local head_r_fat = head_r_muscle + head_t_fat
local head_r_skin = head_r_fat + head_t_skin

-- TORSO dimensions (ellipse approximated as cylinder)
local torso_long_axis = 265/2 -- semi-major axis
local torso_short_axis = 195/2 -- semi-minor axis
local torso_radius = (torso_long_axis + torso_short_axis) / 2 -- average radius
local torso_t_skin = 1.7
local torso_t_fat = 22
local torso_t_muscle = 27
local torso_height = 590

local torso_r_bone = 77 -- from (154+84)/4
local torso_r_muscle = torso_r_bone + torso_t_muscle
local torso_r_fat = torso_r_muscle + torso_t_fat
local torso_r_skin = torso_r_fat + torso_t_skin

-- ARM dimensions (upper arm from paper)
local arm_radius = 96.7
local arm_t_skin = 1.7
local arm_t_fat = 12
local arm_t_muscle = 23
local arm_t_bone = 60 -- radius

local arm_r_bone = arm_t_bone
local arm_r_muscle = arm_r_bone + arm_t_muscle
local arm_r_fat = arm_r_muscle + arm_t_fat
local arm_r_skin = arm_r_fat + arm_t_skin

-- LEG dimensions (thigh from paper)
local leg_t_skin = 2
local leg_t_fat = 17
local leg_t_muscle = 46
local leg_t_bone = 14 -- radius

local leg_r_bone = leg_t_bone
local leg_r_muscle = leg_r_bone + leg_t_muscle
local leg_r_fat = leg_r_muscle + leg_t_fat
local leg_r_skin = leg_r_fat + leg_t_skin

print("Dimensions defined")

-- 6. Helper Function to Draw Body Part Layer
function drawLayer(r_inner, r_outer, z_start, z_end, mat_name)
    -- Draw rectangular region (r_inner to r_outer, z_start to z_end)
    ci_addnode(r_inner, z_start)
    ci_addnode(r_outer, z_start)
    ci_addnode(r_outer, z_end)
    ci_addnode(r_inner, z_end)
    
    ci_addsegment(r_inner, z_start, r_outer, z_start)
    ci_addsegment(r_outer, z_start, r_outer, z_end)
    ci_addsegment(r_outer, z_end, r_inner, z_end)
    ci_addsegment(r_inner, z_end, r_inner, z_start)
    
    -- Add block label at center
    local mid_r = (r_inner + r_outer) / 2
    local mid_z = (z_start + z_end) / 2
    ci_addblocklabel(mid_r, mid_z)
    ci_selectlabel(mid_r, mid_z)
    ci_setblockprop(mat_name, 1, 0, 0)
    ci_clearselected()
end

-- 7. Draw Complete Body Model (stacked vertically)
local z_current = 0

-- LEGS (bottom)
local leg_height = 470 -- thigh + shank
print("Drawing legs...")
drawLayer(0, leg_r_bone, z_current, z_current + leg_height, "Bone")
drawLayer(leg_r_bone, leg_r_muscle, z_current, z_current + leg_height, "Muscle")
drawLayer(leg_r_muscle, leg_r_fat, z_current, z_current + leg_height, "Fat")
drawLayer(leg_r_fat, leg_r_skin, z_current, z_current + leg_height, "Skin")
z_current = z_current + leg_height

-- TORSO (middle)
print("Drawing torso...")
drawLayer(0, torso_r_bone, z_current, z_current + torso_height, "Bone")
drawLayer(torso_r_bone, torso_r_muscle, z_current, z_current + torso_height, "Muscle")
drawLayer(torso_r_muscle, torso_r_fat, z_current, z_current + torso_height, "Fat")
drawLayer(torso_r_fat, torso_r_skin, z_current, z_current + torso_height, "Skin")
z_current = z_current + torso_height

-- NECK (optional, simplified as small cylinder)
local neck_height = 60
local neck_radius = 30
print("Drawing neck...")
drawLayer(0, 23, z_current, z_current + neck_height, "Bone")
drawLayer(23, 40, z_current, z_current + neck_height, "Muscle")
drawLayer(40, 57, z_current, z_current + neck_height, "Fat")
drawLayer(57, 60, z_current, z_current + neck_height, "Skin")
z_current = z_current + neck_height

-- HEAD (top)
local head_height = 160 -- semi-sphere approximated as cylinder
print("Drawing head...")
drawLayer(0, head_r_bone, z_current, z_current + head_height, "Bone")
drawLayer(head_r_bone, head_r_muscle, z_current, z_current + head_height, "Muscle")
drawLayer(head_r_muscle, head_r_fat, z_current, z_current + head_height, "Fat")
drawLayer(head_r_fat, head_r_skin, z_current, z_current + head_height, "Skin")

-- ARM (as separate region on the side - simplified)
local arm_z_start = 600 -- position at torso level
local arm_height = 320
print("Drawing arm...")
drawLayer(torso_r_skin + 10, torso_r_skin + 10 + arm_r_bone, arm_z_start, arm_z_start + arm_height, "Bone")
drawLayer(torso_r_skin + 10 + arm_r_bone, torso_r_skin + 10 + arm_r_muscle, arm_z_start, arm_z_start + arm_height, "Muscle")
drawLayer(torso_r_skin + 10 + arm_r_muscle, torso_r_skin + 10 + arm_r_fat, arm_z_start, arm_z_start + arm_height, "Fat")
drawLayer(torso_r_skin + 10 + arm_r_fat, torso_r_skin + 10 + arm_r_skin, arm_z_start, arm_z_start + arm_height, "Skin")

print("Body geometry created")

-- 8. Add Electrodes (Transmitter pair on torso - T1 location)
-- Paper specifies circular electrodes with 10mm radius, separated by 80mm
local elec_radius = 10
local elec_separation = 80
local elec_z_center = 600 + torso_height/2 -- middle of torso
local elec_thickness = 1 -- 1mm thick copper layer

print("Adding electrodes on torso (T1)...")

-- Electrode 1 (Positive - upper electrode)
local elec1_z = elec_z_center + elec_separation/2
ci_addnode(torso_r_skin, elec1_z - elec_radius)
ci_addnode(torso_r_skin, elec1_z + elec_radius)
ci_addnode(torso_r_skin + elec_thickness, elec1_z + elec_radius)
ci_addnode(torso_r_skin + elec_thickness, elec1_z - elec_radius)

ci_addsegment(torso_r_skin, elec1_z - elec_radius, torso_r_skin + elec_thickness, elec1_z - elec_radius)
ci_addsegment(torso_r_skin + elec_thickness, elec1_z - elec_radius, torso_r_skin + elec_thickness, elec1_z + elec_radius)
ci_addsegment(torso_r_skin + elec_thickness, elec1_z + elec_radius, torso_r_skin, elec1_z + elec_radius)

ci_addblocklabel(torso_r_skin + elec_thickness/2, elec1_z)
ci_selectlabel(torso_r_skin + elec_thickness/2, elec1_z)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

-- Electrode 2 (Ground - lower electrode)
local elec2_z = elec_z_center - elec_separation/2
ci_addnode(torso_r_skin, elec2_z - elec_radius)
ci_addnode(torso_r_skin, elec2_z + elec_radius)
ci_addnode(torso_r_skin + elec_thickness, elec2_z + elec_radius)
ci_addnode(torso_r_skin + elec_thickness, elec2_z - elec_radius)

ci_addsegment(torso_r_skin, elec2_z - elec_radius, torso_r_skin + elec_thickness, elec2_z - elec_radius)
ci_addsegment(torso_r_skin + elec_thickness, elec2_z - elec_radius, torso_r_skin + elec_thickness, elec2_z + elec_radius)
ci_addsegment(torso_r_skin + elec_thickness, elec2_z + elec_radius, torso_r_skin, elec2_z + elec_radius)

ci_addblocklabel(torso_r_skin + elec_thickness/2, elec2_z)
ci_selectlabel(torso_r_skin + elec_thickness/2, elec2_z)
ci_setblockprop("Copper", 1, 0, 0)
ci_clearselected()

print("Electrodes added")

-- 9. Define Boundary Conditions
-- Paper: "Normal component of electric field at skin-air boundary set to zero"
-- In FEMM, this is default (Neumann boundary) - no explicit BC needed

-- However, we need to define voltage on electrodes
ci_addboundprop("Voltage_High", 1, 0, 0, 0) -- 1V
ci_addboundprop("Voltage_Ground", 0, 0, 0, 0) -- 0V (Ground)

-- Apply boundary to electrode segments
-- Select and apply to electrode 1 (positive)
ci_selectsegment(torso_r_skin + elec_thickness, elec1_z)
ci_setsegmentprop("Voltage_High", 0, 1, 0, 0)
ci_clearselected()

-- Apply to electrode 2 (ground)
ci_selectsegment(torso_r_skin + elec_thickness, elec2_z)
ci_setsegmentprop("Voltage_Ground", 0, 1, 0, 0)
ci_clearselected()

print("Boundary conditions applied")

-- 10. Add air region (outer boundary)
local air_radius = 300
local total_height = z_current + head_height

ci_addnode(air_radius, 0)
ci_addnode(air_radius, total_height)
ci_addsegment(air_radius, 0, air_radius, total_height)

ci_addblocklabel(air_radius - 10, total_height/2)
ci_selectlabel(air_radius - 10, total_height/2)
ci_setblockprop("Air", 1, 0, 0)
ci_clearselected()

-- 11. Zoom to fit
ci_zoomnatural()

-- 12. Save the model
ci_saveas("IBC_WholeBody_Model.fec")

print("========================================")
print("Model Generation Complete!")
print("Total body height: " .. total_height .. " mm")
print("Torso radius: " .. torso_r_skin .. " mm")
print("Electrodes at z = " .. elec1_z .. " and " .. elec2_z .. " mm")
print("Model saved as: IBC_WholeBody_Model.fec")
print("========================================")
print("")
print("Next Steps:")
print("1. Mesh the model: ci_createmesh()")
print("2. Analyze: ci_analyze()")
print("3. Load solution: ci_loadsolution()")
print("4. Plot voltage distribution and current density")
print("========================================")

-- Optional: Auto-solve
local response = messagebox("Model created!\n\nDo you want to mesh and solve now?", "Solve", 4)
if response == 6 then
    print("Creating mesh...")
    ci_createmesh()
    print("Analyzing...")
    ci_analyze()
    print("Loading solution...")
    ci_loadsolution()
    print("Solution complete! View results in post-processor.")
end