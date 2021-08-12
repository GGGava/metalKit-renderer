//
//  Shaders.metal
//  VideoTest
//
//  Created by Gustavo Gava on 8/11/21.
//

#include <metal_stdlib>
using namespace metal;

//struct MTLTextureViewVertexOut {
//    float4 position [[ position ]];
//    float2 uv;
//};
//
//vertex MTLTextureViewVertexOut vertexFunc(uint vid [[vertex_id]]) {
//    MTLTextureViewVertexOut out;
//
//    const float2 vertices[] = { float2(-1.0f, 1.0f), float2(-1.0f, -1.0f),
//        float2(1.0f, 1.0f), float2(1.0f, -1.0f)
//    };
//
//    out.position = float4(vertices[vid], 0.0, 1.0);
//    float2 uv = vertices[vid];
//    uv.y = -uv.y;
//    out.uv = fma(uv, 0.5f, 0.5f);
//
//    return out;
//}
//
//fragment half4 fragmentFunc(MTLTextureViewVertexOut in [[stage_in]],
//                            texture2d<half, access::sample> original [[texture(0)]],
//                            texture2d<half, access::sample> blurred [[texture(1)]],
//                            texture2d<half, access::sample> visibilityMask [[texture(2)]])
//{
//    constexpr sampler s(coord::normalized,
//                        address::clamp_to_zero,
//                        filter::linear);
//
//    half4 originalColor = original.sample(s, in.uv);
//    half4 blurredColor = blurred.sample(s, in.uv);
//    half mask = visibilityMask.sample(s, in.uv).r;
//
//    return mix(originalColor, blurredColor, 1.0 - mask);
//}

// 1
struct VertexIn {
  float4 position [[ attribute(0) ]];
};

struct Vertex
{
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    vector_float2 position;

    // 2D texture coordinate
    vector_float2 textureCoordinate;
};

struct RasterizerData
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;

};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant Vertex *vertexArray [[ buffer(0) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])

{

    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    // return the color of the texture
    return float4(colorSample);
}
