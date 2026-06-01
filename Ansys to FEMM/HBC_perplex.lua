-- Open a new electrostatic problem
newdocument(0)
mi_probdef('frequency', 'units', 'depth', 'problem type', 'precision', 'min angle')
mi_probdef(0, 'mm', 1, 'planar', 1e-8, 30)

-- Define materials with conductivity (sigma, S/m) for given frequency
mi_addmaterial('Skin', 4.0e-3, 0, 1)
mi_addmaterial('Fat', 3.0e-2, 0, 1)
mi_addmaterial('Muscle', 3.5e-1, 0, 1)
mi_addmaterial('Bone', 2.0e-2, 0, 1)

-- Define layer radii (external to internal)
r_skin = 96.7     -- mm, outer radius
t_skin = 1.7      -- mm, skin thickness
t_fat = 12        -- mm, fat thickness
t_muscle = 23     -- mm, muscle thickness
t_bone = 60       -- mm, bone radius (innermost, so subtract all previous)

r_fat = r_skin - t_skin
r_muscle = r_fat - t_fat
r_bone = r_muscle - t_muscle

-- Draw each layer as a concentric circle
mi_drawarc(0,0, r_skin,0, 360, 1)
mi_drawarc(0,0, r_fat,0, 360, 1)
mi_drawarc(0,0, r_muscle,0, 360, 1)
mi_drawarc(0,0, r_bone,0, 360, 1)

-- Assign materials to regions (select inside each arc and add block label inside the region)
mi_addblocklabel(r_skin-0.5, 0)
mi_selectlabel(r_skin-0.5, 0)
mi_setblockprop('Skin', 1, 0, '<Auto>', 0, 0, 0)
mi_clearselected()

mi_addblocklabel(r_fat-0.5, 0)
mi_selectlabel(r_fat-0.5, 0)
mi_setblockprop('Fat', 1, 0, '<Auto>', 0, 0, 0)
mi_clearselected()

mi_addblocklabel(r_muscle-0.5, 0)
mi_selectlabel(r_muscle-0.5, 0)
mi_setblockprop('Muscle', 1, 0, '<Auto>', 0, 0, 0)
mi_clearselected()

mi_addblocklabel(r_bone-0.5, 0)
mi_selectlabel(r_bone-0.5, 0)
mi_setblockprop('Bone', 1, 0, '<Auto>', 0, 0, 0)
mi_clearselected()

-- Draw electrodes (as circles or rectangles, e.g., at surface)
mi_addnode(r_skin, 0)
mi_addnode(r_skin * cos(math.pi / 3), r_skin * sin(math.pi / 3))
mi_addsegment(r_skin, 0, r_skin * cos(math.pi / 3), r_skin * sin(math.pi / 3))

-- Set boundary condition (zero normal field at skin-air interface)
mi_addboundprop('ZeroNormalE', 0, 0, 0, 1, 0, 0, 0, 0, 0)
mi_selectarcsegment(r_skin, 0)
mi_setarcsegmentprop(1, 'ZeroNormalE', 0, 0)

-- Save, mesh, and solve
mi_saveas('arm_model.FEM')
mi_analyze()
mi_loadsolution()
