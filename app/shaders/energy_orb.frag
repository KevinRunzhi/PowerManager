#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_center;
uniform float u_radius;
uniform float u_flow_speed;
uniform float u_activation;
uniform float u_pulse;
uniform float u_mist;
uniform float u_overdrawn;
uniform vec4 u_primary;
uniform vec4 u_secondary;
uniform vec4 u_background;
uniform float u_glow_alpha;
uniform float u_noise_amount;

layout(location = 0) out vec4 frag_color;

float hash21(vec2 point) {
  point = fract(point * vec2(123.34, 456.21));
  point += dot(point, point + 45.32);
  return fract(point.x * point.y);
}

float value_noise(vec2 point) {
  vec2 cell = floor(point);
  vec2 local = fract(point);
  local = local * local * (3.0 - 2.0 * local);
  return mix(
    mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), local.x),
    mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), local.x),
    local.y
  );
}

float fbm_two(vec2 point) {
  float first = value_noise(point);
  float second = value_noise(point * 2.03 + vec2(7.1, 3.7));
  return first * 0.68 + second * 0.32;
}

float soft_field(vec2 point, vec2 center, float radius) {
  float distance_to_center = length(point - center) / radius;
  return 1.0 - smoothstep(0.08, 1.0, distance_to_center);
}

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 point = (pixel - u_center) / max(u_radius, 1.0);
  float distance_from_center = length(point);
  float phase = u_time * u_flow_speed;

  float coarse = fbm_two(point * 2.15 + vec2(phase * 0.045, -phase * 0.032));
  float cross_noise = fbm_two(point.yx * 3.4 + vec2(-phase * 0.027, phase * 0.039));
  vec2 warped = point +
    vec2(coarse - 0.5, cross_noise - 0.5) * u_noise_amount;

  vec2 center_a = vec2(
    0.36 * cos(phase * 0.90),
    0.29 * sin(phase * 1.25)
  );
  vec2 center_b = vec2(
    -0.31 * cos(phase * 0.70 + 2.0),
    -0.35 * sin(phase * 0.95 + 1.0)
  );
  vec2 center_c = vec2(
    0.14 * sin(phase * 0.50),
    0.40 * cos(phase * 0.62)
  );

  float overdraft_radius = mix(1.0, 1.12, u_overdrawn);
  float field_a = soft_field(warped, center_a, 0.93 * overdraft_radius);
  float field_b = soft_field(warped, center_b, 0.88 * overdraft_radius);
  float field_c = soft_field(warped, center_c, 0.66);
  float detail = (coarse - 0.5) * mix(0.13, 0.07, u_overdrawn);

  vec3 base_color = mix(
    u_background.rgb,
    u_primary.rgb,
    (0.08 + 0.08 * u_activation) * u_mist
  );
  vec3 fluid_color = mix(
    base_color,
    u_primary.rgb,
    clamp(field_a * 0.68 * u_mist + detail, 0.0, 0.78)
  );
  fluid_color = mix(
    fluid_color,
    u_secondary.rgb,
    clamp(field_b * 0.57 * u_mist - detail * 0.4, 0.0, 0.68)
  );
  fluid_color += u_secondary.rgb * field_c * 0.13 * u_mist;

  float body_mask = 1.0 - smoothstep(0.982, 1.012, distance_from_center);
  float rim = smoothstep(0.91, 0.995, distance_from_center) * body_mask;
  fluid_color = mix(
    fluid_color,
    u_primary.rgb,
    rim * (0.06 + 0.12 * u_activation) * u_mist
  );

  float glow = (1.0 - smoothstep(0.24, 1.65, distance_from_center));
  glow *= u_glow_alpha * (1.0 - body_mask);
  float output_alpha = body_mask + glow * (1.0 - body_mask);
  vec3 premultiplied =
    fluid_color * body_mask + u_primary.rgb * glow * (1.0 - body_mask);

  frag_color = vec4(premultiplied, output_alpha);
}
