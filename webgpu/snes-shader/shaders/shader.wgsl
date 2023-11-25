struct VertOut {
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
fn vertShader(@location(0) uv: vec2<f32>) -> VertOut {
    var out: VertOut;

    out.position = uni.viewProjection * vec4<f32>(uv, 0.0, 1.0);
    out.uv = uv;

    return out;
}

@fragment
fn fragShader(in1: VertOut) -> @location(0) vec4<f32> {
    let texture_dim = textureDimensions(imageTexture);
    let uv = in1.uv;

    // Luma is sampled at full resolution
    // Chroma is downsampled/blurred by a factor of 4 (horizontal axis only)

    let n = f32(texture_dim.x) / 4.0;  // new chroma horizontal resolution
    let f = 1.0 / n / 4.0;  // sub-sampling step (UV coordinates)

    let yuv0 = toYUV(textureSample(imageTexture, imageSampler, uv));
    let yuv1 = toYUV(textureSample(imageTexture, imageSampler, uv + vec2(1*f, 0)));
    let yuv2 = toYUV(textureSample(imageTexture, imageSampler, uv + vec2(2*f, 0)));
    let yuv3 = toYUV(textureSample(imageTexture, imageSampler, uv + vec2(3*f, 0)));

    let luma_only = LUMA_MASK * yuv0;
    let chroma_only = CHROMA_MASK * ((yuv0 + yuv1 + yuv2 + yuv3) / 4);

    return toRGB(luma_only + chroma_only);
}

// BT.601 RGB-to-YUV co-efficents (range: 0.0 to 1.0)
// NOTE: WGSL expects *column*-major storage, so we have to transpose
const YUV: mat4x4<f32> = transpose(mat4x4(
     0.299,  0.587,  0.114, 0, // Y
    -0.169, -0.331,  0.500, 0, // U (Cb)
     0.500, -0.419, -0.081, 0, // V (Cr)
     0.000,  0.000,  0.000, 1  // A
));

const YUV_: mat4x4<f32> = transpose(mat4x4(
     1.000,  0.000,  1.000, 0, // R
     1.000, -0.344, -0.714, 0, // G
     1.000,  1.772,  0.000, 0, // B
     0.000,  0.000,  0.000, 1  // A
));

// Mask for just luma values
const LUMA_MASK: mat4x4<f32> = transpose(mat4x4(
    1, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
));

// Mask for just chroma (UV) values
const CHROMA_MASK: mat4x4<f32> = transpose(mat4x4(
    0, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 0,
));

// RGB(A) (range: 0.0-1.0) to YUV(A) (range: 0.0-1.0)
// This means that 0.5 is the center of U/V values
fn toYUV(rgba: vec4<f32>) -> vec4<f32> {
    return YUV * rgba;
}

// Takes YUVA (range: 0.0-1.0) and converts to RGBA (range: 0.0-1.0)
fn toRGB(yuva: vec4<f32>) -> vec4<f32> {
    return YUV_ * yuva;
}
