struct VertexOut {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

struct Uniforms {
    viewProjection: mat4x4<f32>,
};

@group(0) @binding(0) var sourceSampler: sampler;
@group(0) @binding(1) var intermediateTexture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> uni: Uniforms;
@group(0) @binding(3) var sourceTexture: texture_external;

@vertex
fn vertShader(@location(0) uv: vec2<f32>) -> VertexOut {
    var out: VertexOut;

    out.position = uni.viewProjection * vec4<f32>(uv, 0.0, 1.0);
    out.uv = vec2(uv.x, 1.0 - uv.y);

    return out;
}

// Applies horizontal chroma subsampling to source.
@fragment
fn fragShader1(in1: VertexOut) -> @location(0) vec4<f32> {
    let texture_dim = textureDimensions(sourceTexture);

    // Luma is sampled at full resolution
    // Chroma is downsampled/blurred by a factor of 4 (horizontal axis only)
    let f = 1.0 / f32(texture_dim.x);

    let yuvl = toYUV(textureSampleBaseClampToEdge(sourceTexture, sourceSampler, in1.uv));

    // This is sampling across 8 pixels, which seems to many, but looks right.
    var yuvc = vec4(0.0, 0.0, 0.0, 0.0);
    for (var n: f32 = -4.0; n < 4.0; n += 1.0) {
        yuvc += toYUV(textureSampleBaseClampToEdge(sourceTexture, sourceSampler, in1.uv + vec2(n * f, 0)));
    }

    let luma_only = LUMA_MASK * yuvl;
    let chroma_only = CHROMA_MASK * (yuvc / 8.0);

    return toRGB(luma_only + chroma_only);
}

// Applies chromatic abberation to source.
@fragment
fn fragShader2(in1: VertexOut) -> @location(0) vec4<f32> {
    let texture_dim = textureDimensions(intermediateTexture);

    let f = 1.0 / f32(texture_dim.x);

    let red = textureSampleBaseClampToEdge(intermediateTexture, sourceSampler, in1.uv);
    let green = textureSampleBaseClampToEdge(intermediateTexture, sourceSampler, in1.uv + vec2(1.0 * f, 0));
    let blue = textureSampleBaseClampToEdge(intermediateTexture, sourceSampler, in1.uv + vec2(2.0 * f, 0));

    return vec4(red.r, green.g, blue.b, red.a);
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
