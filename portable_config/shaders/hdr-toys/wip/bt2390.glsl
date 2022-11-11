// https://github.com/haasn/libplacebo/blob/master/src/tone_mapping.c#L266

static void bt2390(float *lut, const struct pl_tone_map_params *params)
{
    const float minLum = rescale_in(params->output_min, params);
    const float maxLum = rescale_in(params->output_max, params);
    const float offset = params->param;
    const float ks = (1 + offset) * maxLum - offset;
    const float bp = minLum > 0 ? fminf(1 / minLum, 4) : 4;
    const float gain_inv = 1 + minLum / maxLum * powf(1 - maxLum, bp);
    const float gain = maxLum < 1 ? 1 / gain_inv : 1;

    FOREACH_LUT(lut, x) {
        x = rescale_in(x, params);

        // Piece-wise hermite spline
        if (ks < 1) {
            float tb = (x - ks) / (1 - ks);
            float tb2 = tb * tb;
            float tb3 = tb2 * tb;
            float pb = (2 * tb3 - 3 * tb2 + 1) * ks +
                       (tb3 - 2 * tb2 + tb) * (1 - ks) +
                       (-2 * tb3 + 3 * tb2) * maxLum;
            x = x < ks ? x : pb;
        }

        // Black point adaptation
        if (x < 1) {
            x += minLum * powf(1 - x, bp);
            x = gain * (x - minLum) + minLum;
        }

        x = x * (params->input_max - params->input_min) + params->input_min;
    }
}