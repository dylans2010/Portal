#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    return out;
}

struct Uniforms {
    float time;
    int state;
    float stateTime;
    float2 resolution;
    float pitch;
    float roll;
    float yaw;
};

// Helper functions for complex noise and shapes
float hash(float n) { return fract(sin(n) * 43758.5453123); }

float noise(float3 x) {
    float3 p = floor(x);
    float3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
                   mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}

float circle(float2 p, float2 center, float radius, float feather) {
    return 1.0 - smoothstep(radius - feather, radius + feather, length(p - center));
}

float ring(float2 p, float2 center, float radius, float width, float feather) {
    float d = length(p - center);
    return smoothstep(radius - width - feather, radius - width, d) * (1.0 - smoothstep(radius - feather, radius + feather, d));
}

float3 palette(float t) {
    float3 a = float3(0.5, 0.5, 0.5);
    float3 b = float3(0.5, 0.5, 0.5);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.0, 0.33, 0.67);

    // More complex palette with more colors
    float3 col1 = a + b * cos(6.28318 * (c * t + d));
    float3 col2 = a + b * cos(6.28318 * (c * (t + 0.5) + d + float3(0.5, 0.2, 0.1)));

    return mix(col1, col2, sin(t) * 0.5 + 0.5);
}

fragment float4 fragment_main(float4 position [[stage_in]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = position.xy / uniforms.resolution;
    float2 p = (position.xy * 2.0 - uniforms.resolution) / min(uniforms.resolution.x, uniforms.resolution.y);

    // Apply motion offset
    float2 motionOffset = float2(uniforms.roll, -uniforms.pitch) * 0.2;
    p += motionOffset;

    float4 color = float4(0.0);

    if (uniforms.state == 1) { // Loading: Complex plasma-like effect
        float2 p0 = p;
        float3 finalColor = float3(0.0);

        // Increase iterations for more intensity and color complexity
        for (float i = 0.0; i < 5.0; i++) {
            p = fract(p * 1.5) - 0.5;
            float d = length(p) * exp(-length(p0));

            // Generate over 10 dynamically moving colors by combining multiple palette shifts
            float3 col = palette(length(p0) + i * 0.4 + uniforms.time * 0.3);
            float3 col2 = palette(length(p) + i * 0.2 - uniforms.time * 0.2);
            col = mix(col, col2, 0.5 + 0.5 * sin(uniforms.time + i));

            d = sin(d * 8.0 + uniforms.time) / 8.0;
            d = abs(d);
            d = pow(0.01 / d, 1.2);
            finalColor += col * d;
        }

        // Add a central rotating geometric shape
        float r = length(p0);
        float angle = atan2(p0.y, p0.x) + uniforms.time * 2.0;
        float shape = smoothstep(0.4, 0.41, abs(sin(angle * 3.0)) * 0.1 + r);
        finalColor *= (1.0 - (1.0 - shape) * 0.5);

        color = float4(finalColor * 0.8, 0.95); // Increased intensity

    } else if (uniforms.state == 2) { // Success: Radiant energy burst
        float t = uniforms.stateTime;
        float2 p0 = p;

        // Expanding rings with motion
        float burst = 0.0;
        for(float i = 0.0; i < 5.0; i++) {
            float radius = t * (1.0 + i * 0.5);
            burst += ring(p, float2(0.0), radius, 0.02, 0.05) * (1.0 - smoothstep(0.0, 2.0, t));
        }

        // Background color shift to green
        float3 successCol = float3(0.0, 0.8, 0.4);
        float bgFade = smoothstep(0.0, 0.8, t) * (1.0 - smoothstep(1.5, 2.0, t));

        float3 finalColor = successCol * burst + successCol * bgFade * 0.2;

        // Add particles
        float particles = 0.0;
        for(float i = 0.0; i < 10.0; i++) {
            float2 pos = float2(sin(i * 123.4 + uniforms.time), cos(i * 567.8 + uniforms.time)) * t * 0.8;
            particles += circle(p, pos, 0.02 * (1.0 - t/2.0), 0.01);
        }
        finalColor += float3(1.0) * particles * (1.0 - t/2.0);

        color = float4(finalColor, 0.85);

    } else if (uniforms.state == 3) { // Error: Glitchy red distortion
        float t = uniforms.stateTime;
        float2 p0 = p;

        // Glitch offset
        float glitch = step(0.95, hash(uniforms.time)) * (hash(uniforms.time * 1.1) - 0.5) * 0.2;
        p.x += glitch;

        // Red noise background
        float n = noise(float3(p * 4.0, uniforms.time * 2.0));
        float3 errorCol = float3(0.8, 0.1, 0.1) * (0.5 + 0.5 * n);

        // Vignette with motion
        float vignette = 1.0 - smoothstep(0.3, 1.2, length(p0 - motionOffset * 2.0));
        errorCol *= vignette;

        // Sharp X shape or similar
        float cross = smoothstep(0.01, 0.0, abs(p.x - p.y) - 0.01) + smoothstep(0.01, 0.0, abs(p.x + p.y) - 0.01);
        errorCol += float3(1.0, 0.5, 0.5) * cross * 0.3 * (0.8 + 0.2 * sin(uniforms.time * 20.0));

        color = float4(errorCol, 0.9);
    }

    // Rounded corners mask
    float2 cornerDist = abs(uv - 0.5) * uniforms.resolution;
    float2 cornerLimit = uniforms.resolution * 0.5 - 28.0; // 28 is corner radius
    float d = length(max(cornerDist - cornerLimit, 0.0)) - 28.0;
    float cornerMask = 1.0 - smoothstep(-1.0, 1.0, d);

    return color * cornerMask;
}
