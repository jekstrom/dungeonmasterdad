shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 pocket_cells = vec2(3.0, 3.0);
uniform vec2 cell_in_pocket = vec2(0.0, 0.0);
uniform vec2 pocket_px_override = vec2(0.0, 0.0);
uniform float tile_px = 128.0;
uniform float corner_px = 44.0;
uniform float ice_alpha = 0.34;
uniform vec4 ice_tint : source_color = vec4(0.74, 0.93, 1.0, 1.0);
uniform float glint_strength = 0.2;

void fragment() {
	vec2 cells = max(pocket_cells, vec2(1.0));
	vec2 pocket_px = cells * tile_px;
	vec2 local_px;
	vec4 ice;
	if (pocket_px_override.x > 0.5 && pocket_px_override.y > 0.5) {
		pocket_px = pocket_px_override;
		ice = texture(TEXTURE, UV * cells);
		local_px = UV * pocket_px;
	} else {
		ice = texture(TEXTURE, UV);
		local_px = (cell_in_pocket + UV) * tile_px;
	}
	vec2 half_size = pocket_px * 0.5;
	vec2 p = local_px - half_size;
	float r = min(corner_px, min(half_size.x, half_size.y) * 0.48);
	vec2 q = abs(p) - half_size + vec2(r);
	float sdf = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
	float mask = 1.0 - smoothstep(-2.4, 2.4, sdf);

	vec2 gp = local_px / max(tile_px, 1.0);
	float t = TIME;
	float spark = pow(max(sin(gp.x * 8.6 + t * 0.62) * sin(gp.y * 6.4 - t * 0.47), 0.0), 16.0);
	float sweep = pow(clamp(1.0 - abs(fract(gp.x * 0.28 + gp.y * 0.46 + t * 0.06) - 0.5) * 11.0, 0.0, 1.0), 9.0);
	float glint = (spark * 0.7 + sweep * 0.5) * glint_strength;

	vec3 col = mix(ice.rgb, ice_tint.rgb, 0.32);
	col += vec3(0.88, 0.96, 1.0) * glint;
	float alpha = ice.a * ice_alpha * mask + glint * 0.1 * mask;
	COLOR = vec4(col, clamp(alpha, 0.0, 0.55));
}
