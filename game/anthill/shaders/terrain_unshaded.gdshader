shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	ALBEDO = vcol.rgb;
}
