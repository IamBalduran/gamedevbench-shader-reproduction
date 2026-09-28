extends SceneTree

func _init():
	var scene: PackedScene = load("res://scenes/audio_demo.tscn")
	var root: MarginContainer = scene.instantiate()
	
	print("=== Scene Validation ===")
	print("Name: '%s' (expected 'AudioDemo')" % root.name)
	assert(root.name == "AudioDemo", "Root name mismatch")
	
	# Check margins
	var ml = root.get_theme_constant("margin_left")
	var mr = root.get_theme_constant("margin_right")
	var mt = root.get_theme_constant("margin_top")
	var mb = root.get_theme_constant("margin_bottom")
	print("Margins: L=%d R=%d T=%d B=%d" % [ml, mr, mt, mb])
	assert(ml == 20 and mr == 20 and mt == 20 and mb == 20, "Margin mismatch")
	
	# Check anchor/fill
	print("Anchor right=%.1f bottom=%.1f" % [root.anchor_right, root.anchor_bottom])
	assert(root.anchor_right == 1.0 and root.anchor_bottom == 1.0, "Root should fill screen")
	
	# Check CenterContainer child
	var cc = root.get_node_or_null("CenterContainer")
	assert(cc != null, "Missing CenterContainer")
	print("CenterContainer: OK (%s)" % cc.get_class())
	
	# Check GridContainer
	var gc = cc.get_node_or_null("GridContainer")
	assert(gc != null, "Missing GridContainer")
	assert(gc.columns == 2, "GridContainer columns should be 2")
	var hs = gc.get_theme_constant("h_separation")
	var vs = gc.get_theme_constant("v_separation")
	print("GridContainer: columns=%d h_sep=%d v_sep=%d" % [gc.columns, hs, vs])
	assert(hs == 10 and vs == 10, "Grid separation mismatch")
	
	# Check CanvasLayer
	var cl = root.get_node_or_null("CanvasLayer")
	assert(cl != null, "Missing CanvasLayer")
	print("CanvasLayer: OK")
	
	# Check HBoxContainer
	var hbox = cl.get_node_or_null("HBoxContainer")
	assert(hbox != null, "Missing HBoxContainer")
	print("HBoxContainer: OK")
	
	# Check Label
	var label = hbox.get_node_or_null("Label")
	assert(label != null, "Missing Label")
	assert(label.name == "Label", "Label name mismatch")
	print("Label: name='%s' text='%s'" % [label.name, label.text])
	assert(label.get_theme_font_size("font_size") == 24, "Font size should be 24")
	print("Label font size: %d" % label.get_theme_font_size("font_size"))
	
	# Check sound_dir export
	var script: GDScript = root.get_script()
	print("Script: %s" % script.resource_path)
	print("sound_dir default: %s" % script.get_script_property_list().filter(func(d): return d.name == "sound_dir")[0])
	
	print("\n=== All validations passed ===")
	quit()