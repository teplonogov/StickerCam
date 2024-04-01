#include <metal_stdlib>

using namespace metal;

kernel void stickerKernel(texture2d<float, access::read> sticker [[ texture(0) ]],
                          texture2d<float, access::read> paperMask [[ texture(1) ]],
                          texture2d<float, access::read> paperTexture [[ texture(2) ]],
                          texture2d<float, access::write> destination [[ texture(3) ]],
                          uint2 position [[thread_position_in_grid]]) {
    float4 stickerValue = sticker.read(position);
    float4 paperMaskValue = paperMask.read(position);
    float4 paperTextureValue = paperTexture.read(position);

    float4 maskedPaperTexture = paperTextureValue * paperMaskValue.r;

    float4 resultColor;
    if (stickerValue.a < 1.0) {
        resultColor = maskedPaperTexture;
    } else {
        resultColor = stickerValue;
    }

    destination.write(resultColor, position);
}

kernel void alphaMaskKernel(texture2d<float, access::read> source [[ texture(0) ]],
                            texture2d<float, access::write> destination [[ texture(1) ]],
                            uint2 position [[thread_position_in_grid]]) {
    const float4 sourceValue = source.read(position);
    float4 result;
    if (sourceValue.a > 0) {
        result = float4(1,1,1,1);
    } else {
        result = float4(0,0,0,0);
    }
    
    destination.write(result, position);
}

kernel void paperMaskKernel(texture2d<float, access::read> stickerMask [[ texture(0) ]],
                            texture2d<float, access::read> strokeMask [[ texture(1) ]],
                            texture2d<float, access::write> destination [[ texture(2) ]],
                            uint2 position [[thread_position_in_grid]]) {
    const float stickerValue = stickerMask.read(position).r;
    const float strokeValue = strokeMask.read(position).r;
    
    const float result = saturate(stickerValue + strokeValue);
    
    destination.write(float4(result, result, result, 1), position);
}

struct Point {
    float4 position [[position]];
    float4 color;
    float angle;
    float size [[point_size]];
    float hardness;
};

vertex Point vertex_point_func(constant Point *points [[ buffer(0) ]],
                               uint vid [[ vertex_id ]])
{
    Point out = points[vid];

    return out;
};

float2 transformPointCoord(float2 pointCoord, float a, float2 anchor) {
    float2 point20 = pointCoord - anchor;
    float x = point20.x * cos(a) - point20.y * sin(a);
    float y = point20.x * sin(a) + point20.y * cos(a);
    return float2(x, y) + anchor;
}

fragment float4 fragment_point_func(Point point_data [[ stage_in ]],
                                    texture2d<float> tex2d [[ texture(0) ]],
                                    constant float4 &brushColor [[ buffer(0) ]],
                                    float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 text_coord = transformPointCoord(pointCoord, point_data.angle, float2(0.5));

    float4 color = float4(tex2d.sample(textureSampler, text_coord));
    float d = distance(float2(0.5), pointCoord);
    float h = smoothstep(point_data.hardness / 2, 0.5, d);

    return float4(brushColor.rgb, color.a * brushColor.a * (1 - h));//color.a * brushColor.a * (1 - h));
};
