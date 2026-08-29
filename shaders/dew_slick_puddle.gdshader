shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D water_tex : repeat_enable, filter_linear;
uniform vec4 teal : source_color = vec4(0.05, 0.92, 0.82, 0.55);
uniform vec2 puddle_px = vec2(128.0, 128.0);
uniform float tile_px = 128.0;
uniform float flow_speed = 0.14;
uniform float ripple_amp = 0.045;

void fragment() {
	vec2 tiles = max(puddle_px / max(tile_px, 1.0), vec2(1.0));
	vec2 base_uv = UV * tiles;
	float t = TIME * flow_speed;
	vec2 n1 = texture(water_tex, base_uv + vec2(t * 0.7, t * 0.22)).rg;
	vec2 n2 = texture(water_tex, base_uv * 1.31 + vec2(-t * 0.48, t * 0.61)).gb;
	vec2 warp = (n1 - 0.5) * ripple_amp + (n2 - 0.5) * ripple_amp * 0.7;
	vec3 water = texture(water_tex, base_uv + warp + vec2(0.0, sin(TIME * 0.7 + UV.x * 6.28318) * 0.012)).rgb;
	float caustic = clamp((water.g - water.r) * 3.4 + water.b * 0.32, 0.0, 1.0);

	vec2 edge = abs(UV - vec2(0.5)) * 2.0;
	float box = max(edge.x, edge.y);
	float rim = smoothstep(0.8, 0.98, box);
	float falloff = 1.0 - smoothstep(0.93, 1.03, box);

	float body_a = mix(teal.a * 0.4, teal.a, caustic);
	float alpha = (body_a + rim * 0.22) * falloff;

	vec3 col = mix(teal.rgb * 0.4, teal.rgb, 0.52 + caustic * 0.48);
	col += vec3(0.62, 0.98, 0.92) * caustic * 0.3;
	col = mix(col, vec3(0.8, 1.0, 0.97), rim * 0.48);
	COLOR = vec4(col, clamp(alpha, 0.0, 0.72));
}
