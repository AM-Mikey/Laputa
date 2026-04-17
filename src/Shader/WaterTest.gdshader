shader_type canvas_item;

// ── World-space positioning ────────────────────────────────────────────────
// Set these from GDScript on the ColorRect/Polygon2D each frame (or on ready
// if the node never moves):
//
//   water.material.set_shader_parameter("world_position", water.global_position)
//   water.material.set_shader_parameter("rect_size",      water.size)
//
uniform vec2 world_position = vec2(0.0);     // global_position of the node
uniform vec2 rect_size      = vec2(320.0, 96.0); // size in pixels
uniform vec2 camera_zoom    = vec2(1.0, 1.0);  // get_viewport().get_camera_2d().zoom
uniform vec2 scroll_speed = vec2(0.1, 0.0);

// ── Fill texture ───────────────────────────────────────────────────────────
uniform sampler2D fill_texture : repeat_enable, hint_default_white, filter_nearest;
// How many pixels one tile of the texture covers in world space.
// e.g. vec2(32, 32) means the texture repeats every 32 px.
uniform vec2 texture_tile_size = vec2(32.0, 32.0);

// ── Edge line ──────────────────────────────────────────────────────────────
uniform vec4 edge_color : source_color  = vec4(1.0, 1.0, 1.0, 1.0) ;
// Total width of the edge line in pixels (split evenly above/below surface).
uniform float edge_thickness = 2.0;

// ── Wave parameters ────────────────────────────────────────────────────────
// base_y_frac: resting surface as a fraction of rect height (0 = top, 1 = bottom).
uniform float base_y_frac       = 0.25;
// Amplitude and frequency are in pixels so they stay consistent regardless of
// how tall or wide the rect is.
uniform float wave_amplitude_px = 4.0;   // peak displacement in pixels
uniform float wave_frequency_px = 0.04;  // cycles per pixel of width
uniform float wave_speed        = 2.0;


void fragment() {
    // ── Convert UV → local pixel coordinate ─────────────────────────────
    // We reconstruct local pixel position from UV and the known rect size.
    // (0, 0) = top-left corner of the node, (rect_size) = bottom-right.
    vec2 local_px = UV * rect_size;
	vec2 world_px = world_position + local_px;

    // ── Wave surface in pixel space ──────────────────────────────────────
    vec2 tile_uv = (world_px / (texture_tile_size * camera_zoom * 0.5)) + TIME * scroll_speed;
    vec4 tex_color = texture(fill_texture, tile_uv);
    float base_px = base_y_frac * rect_size.y;

    // Two overlapping sine waves keyed to the local X pixel position.
    // Because frequency is per-pixel, the wave pattern looks identical
    // regardless of how wide the rect is.
    float wave1 = sin(local_px.x * wave_frequency_px       + TIME * wave_speed);
    float wave2 = sin(local_px.x * wave_frequency_px * 0.5 + TIME * wave_speed * 0.8);
    float surface_px = base_px - ((wave1 + wave2) * 0.5) * wave_amplitude_px;

    // Blend texture with flat tint color
    vec4 fill_color = tex_color;//mix( * water_color, water_color, color_mix);

    // ── Classify this fragment ───────────────────────────────────────────
    // dist_from_surface: negative = above water, positive = below water
    float dist_from_surface = local_px.y - surface_px;
    float half_edge = edge_thickness * 0.5;

    bool above_water = dist_from_surface < -half_edge;
    bool on_edge     = abs(dist_from_surface) <= half_edge;
    // Anything else is below the edge → water body fill

    // ── Compose final color ──────────────────────────────────────────────
    if (above_water) {
        // Fully transparent — sky / background shows through
        COLOR = vec4(0.0);
    } else if (on_edge) {
        // Hard pixel-width edge line
        COLOR = edge_color;
    } else {
        // Water body
        COLOR = vec4(fill_color.rgba);
    }
}
