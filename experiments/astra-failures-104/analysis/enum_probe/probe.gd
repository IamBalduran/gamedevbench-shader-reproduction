extends SceneTree
func _initialize():
 print("SIZE_EXPAND_FILL=", Control.SIZE_EXPAND_FILL, "; SIZE_SHRINK_CENTER=", Control.SIZE_SHRINK_CENTER)
 var mismatch = 0
 for i in range(-31415, 31416):
  var a = float(i) / 10000.0
  var x = wrapi(int(round(a / (PI / 4.0))), 0, 8)
  var y = wrapi(int(snappedf(a, PI / 4.0) / (PI / 4.0)), 0, 8)
  if x != y: mismatch += 1
 print("sampled_angles=62831; round_vs_snappedf_mismatches=", mismatch)
 quit()
