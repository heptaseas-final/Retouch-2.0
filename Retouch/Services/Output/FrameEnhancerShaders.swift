import Foundation

enum FrameEnhancerShaders {

    static let source = #"""
    #include <metal_stdlib>
    using namespace metal;

    struct EnhanceUniforms {
        float spatial;
        float noise;
        float chroma;
        float sharpen;
        float coring;
        float night;
        float hasHistory;
    };

    kernel void enhance(
        texture2d<float, access::read> input [[texture(0)]],
        texture2d<float, access::write> output [[texture(1)]],
        texture2d<float, access::read> historyIn [[texture(2)]],
        texture2d<float, access::write> historyOut [[texture(3)]],
        constant EnhanceUniforms &u [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
    ) {

        uint width = output.get_width();
        uint height = output.get_height();

        if (gid.x >= width || gid.y >= height) {
            return;
        }

        float4 center = input.read(gid);

        if (u.spatial <= 0.001 &&
            u.chroma <= 0.001 &&
            u.sharpen <= 0.001 &&
            u.night <= 0.001) {

            output.write(center, gid);
            return;
        }

        float3 original = center.rgb;

        float3 gaussianSum = float3(0.0);
        float gaussianWeightSum = 0.0;

        float3 bilateralSum = float3(0.0);
        float bilateralWeightSum = 0.0;

        int2 maxPosition = int2(
            int(width) - 1,
            int(height) - 1
        );

        float sigma = 0.025 + 0.08 * u.noise;
        float sigmaSquared = 2.0 * sigma * sigma;

        // Toleransi khusus warna: cukup lebar untuk meloloskan noise (supaya tetap dihaluskan),
        // tapi tepi warna yang jelas (bibir, eyeliner, eyeshadow) tetap tidak dilewati.
        float chromaSigma = 0.05 + 0.16 * u.noise;
        float chromaSigmaSquared = 2.0 * chromaSigma * chromaSigma;
        float3 chromaSum = float3(0.0);
        float chromaWeightSum = 0.0;

        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {

                int2 position = clamp(
                    int2(gid) + int2(dx, dy),
                    int2(0),
                    maxPosition
                );

                float3 sampleColor = input.read(
                    uint2(position)
                ).rgb;

                float distanceSquared = float(
                    dx * dx + dy * dy
                );

                float spatialWeight = exp(
                    -distanceSquared / 2.0
                );

                float3 difference = sampleColor - original;

                float colorDistance = dot(
                    difference,
                    difference
                );

                float rangeWeight = exp(
                    -colorDistance / sigmaSquared
                );

                float bilateralWeight =
                    spatialWeight * rangeWeight;

                gaussianSum += sampleColor * spatialWeight;
                gaussianWeightSum += spatialWeight;

                bilateralSum += sampleColor * bilateralWeight;
                bilateralWeightSum += bilateralWeight;

                float chromaWeight = spatialWeight * exp(-colorDistance / chromaSigmaSquared);
                chromaSum += sampleColor * chromaWeight;
                chromaWeightSum += chromaWeight;
            }
        }

        float3 gaussian = gaussianSum /
            max(gaussianWeightSum, 0.0001);

        float3 bilateral = bilateralSum /
            max(bilateralWeightSum, 0.0001);

        const float3 kLuma = float3(0.2126, 0.7152, 0.0722);

        float3 denoised = mix(original, bilateral, u.spatial);

        // Night: "diam dulu, lalu menetap". Setiap piksel punya umur (jumlah
        // frame berturut-turut yang diam), disimpan di alpha history. Selama
        // diam, umur naik dan bobot history naik (rata-rata beberapa frame,
        // noise turun). Begitu piksel bergerak, umur kembali ke 1 dan
        // gambar langsung mengikuti frame terbaru (tanpa ghosting).
        // History disimpan sebelum tone mapping agar shadow lift tidak menumpuk.
        if (u.night > 0.001) {
            float count = 0.0;
            float w = 0.0;
            float still = 0.0;
            if (u.hasHistory > 0.5) {
                float4 stored = historyIn.read(gid);
                float3 change = denoised - stored.rgb;
                float sigmaT = 0.03 + 0.10 * u.noise;
                still = exp(-dot(change, change) / (2.0 * sigmaT * sigmaT));
                count = stored.a * 8.0;
                w = min(count / (count + 1.0), 0.85 * u.night) * still;
                denoised = mix(denoised, stored.rgb, w);
            }
            float newCount = min(count * still + 1.0, 8.0);
            historyOut.write(float4(denoised, newCount / 8.0), gid);
        }

        float y = dot(denoised, kLuma);

        // Chroma dihaluskan dengan filter yang mengikuti tepi (bukan Gaussian biasa),
        // supaya warna bibir/alis/eyeliner tidak merembes ke kulit di sebelahnya.
        float3 chroma = denoised - y;
        float3 chromaFiltered = chromaSum / max(chromaWeightSum, 0.0001);
        float3 chromaSmooth = chromaFiltered - dot(chromaFiltered, kLuma);
        float3 result = y + mix(chroma, chromaSmooth, u.chroma);

        // Night: kecerahan diangkat di ruang linear dengan gain yang SAMA untuk
        // R, G, B (seperti eksposur lebih panjang), jadi rasio warna dan warna
        // kulit tetap. Gain paling besar di bayangan dan menuju 1 di highlight.
        // Gain dikurangi saat noise sensor tinggi supaya noise tidak diperbesar.
        float detailGain = 1.0;
        if (u.night > 0.001) {
            float3 linear = pow(max(result, 0.0), 2.2);
            float lumaLinear = dot(linear, kLuma);
            float strength = 0.7 * u.night * (1.0 - 0.4 * u.noise);
            float gain = 1.0 + strength * pow(1.0 - saturate(lumaLinear), 2.0);
            result = pow(saturate(linear * gain), 1.0 / 2.2);
            detailGain = pow(gain, 1.0 / 2.2);
        }

        if (u.sharpen > 0.001) {
            float detail = dot(original, kLuma) - dot(gaussian, kLuma);
            float thresholdedDetail = sign(detail) * max(abs(detail) - u.coring * detailGain, 0.0);

            float brightest = max(original.r, max(original.g, original.b));
            float highlightGuard = 1.0 - smoothstep(0.85, 1.0, brightest);

            result += thresholdedDetail * u.sharpen * highlightGuard * detailGain;
        }

        result = clamp(result, 0.0, 1.0);

        output.write(
            float4(result, center.a),
            gid
        );
    }
    """#
}
