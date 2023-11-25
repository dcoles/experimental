struct VSOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@vertex
fn main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec3<f32>) -> VSOutput {
    var vs_out: VSOutput;

    vs_out.position = vec4<f32>(in_pos, 1.0);
    vs_out.color = in_color;

    return vs_out;
}
