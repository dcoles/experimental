struct VSOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

struct Uniforms {
    viewProjection: mat4x4<f32>,
};

@group(0) @binding(0) var imageSampler: sampler;
@group(0) @binding(1) var imageTexture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> uni: Uniforms;

@vertex
fn vertShader(@location(0) uv: vec2<f32>) -> VSOutput {
    var vs_out: VSOutput;

    vs_out.position = uni.viewProjection * vec4<f32>(uv, 0.0, 1.0);
    vs_out.uv = uv;

    return vs_out;
}

@fragment
fn fragShader(input: VSOutput) -> @location(0) vec4<f32> {
    return textureSample(imageTexture, imageSampler, input.uv);
}
