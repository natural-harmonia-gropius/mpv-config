// https://github.com/haasn/libplacebo/blob/master/src/tone_mapping.c#L424

static void mobius(float *lut, const struct pl_tone_map_params *params)
{
    const float peak = rescale(params->input_max, params),
                j = params->param;

    // Solve for M(j) = j; M(peak) = 1.0; M'(j) = 1.0
    // where M(x) = scale * (x+a)/(x+b)
    const float a = -j*j * (peak - 1.0f) / (j*j - 2.0f * j + peak);
    const float b = (j*j - 2.0f * j * peak + peak) /
                    fmaxf(1e-6f, peak - 1.0f);
    const float scale = (b*b + 2.0f * b*j + j*j) / (b - a);

    FOREACH_LUT(lut, x) {
        x = rescale(x, params);
        x = x <= j ? x : scale * (x + a) / (x + b);
        x = rescale_out(x, params);
    }
}