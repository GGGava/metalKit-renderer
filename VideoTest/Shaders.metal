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

// 2
vertex float4 vertex_main(const VertexIn vertexIn [[ stage_in ]],
                          constant float &timer [[ buffer(1) ]]) {
  float4 position = vertexIn.position;
  position.y += timer;
  return position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
