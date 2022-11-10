/* vi: ft=c
 *
 * Based on vf_nlmeans.c from FFmpeg.
 *
 * Copyright (c) 2022 an3223 <ethanr2048@gmail.com>
 * Copyright (c) 2016 Clément Bœsch <u pkh me>
 *
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation, either version 2.1 of the License, or (at 
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (downscale)
//!WIDTH HOOKED.w 2.0 /
//!HEIGHT HOOKED.h 2.0 /
//!SAVE DOWNSCALED

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (downscale)
//!WIDTH HOOKED.w 1.25 /
//!HEIGHT HOOKED.h 1.25 /
//!SAVE DOWNSCALED_LUMA

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC Non-local means (EP downscale)
//!WIDTH HOOKED.w 3 /
//!HEIGHT HOOKED.h 3 /
//!SAVE EP_LUMA

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!BIND DOWNSCALED
//!BIND DOWNSCALED_LUMA
//!BIND EP_LUMA
//!BIND PREV1
//!BIND PREV2
//!BIND PREV3
//!BIND PREV4
//!BIND PREV5
//!BIND PREV6
//!BIND PREV7
//!BIND PREV8
//!BIND PREV9
//!BIND PREV10
//!DESC Non-local means

/* User variables
 *
 * S = denoising factor
 * P = patch size (odd number)
 * R = research size (odd number)
 * SS = spatial denoising factor
 *
 * A higher denoising factor will increase the denoising effect.
 *
 * With a higher spatial denoising factor, distant pixels will contribute less.
 *
 * Patch size should usually be 3. Higher values are not always better.
 *
 * Research size should be at least 3. Higher values are usually better, but 
 * slower and offer diminishing returns.
 *
 * It is usually preferable to denoise chroma and luma differently, so the user 
 * variables for luma and chroma are split.
 *
 * Suggested settings (assume defaults for unspecified parameters):
 * 	- Film (especially black and white):
 * 		- Disable chroma by removing the HOOK CHROMA lines above
 * 	- HQ (slow):
 * 		- LUMA=S=3:PS=3:WD=2:RI=1
 * 		- CHROMA=PS=3
 * 	- LQ (fast):
 * 		- LUMA=P=1
 * 		- CHROMA=P=1
 * 	- Sharp:
 * 		- LUMA=S=9:AS=1:EP=0
 *
 * It is recommended to make multiple copies of this shader with settings 
 * tweaked for different types of content, and then dispatch the appropriate 
 * one via keybinds in input.conf, e.g.:
 *
 * F4 no-osd change-list glsl-shaders toggle "~~/shaders/nlmeans_luma.glsl"; show-text "Non-local means (LUMA only)"
 *
 * The shader can also be enabled by default in mpv.conf:
 *
 * glsl-shaders='~~/shaders/nlmeans.glsl'
 *
 * Both of the examples above assume the shader(s) being located in a 
 * subdirectory named "shaders" inside of mpv's config directory. Refer to the 
 * mpv documentation for more details.
 */
#ifdef LUMA_raw
#define S 1.25
#define P 3
#define R 5
#define SS 0.25
#else
#define S 2.0
#define P 3
#define R 5
#define SS 0.25
#endif

/* Adaptive sharpening
 *
 * Uses the blur incurred by denoising plus the weight map to perform an 
 * unsharp mask that gets applied most strongly to edges.
 *
 * Increasing sharpness will increase noise, so S should usually be increased 
 * to compensate.
 *
 * AS: 2 for sharpening, 1 for sharpening+denoising, 0 to disable
 * ASF: Sharpening factor, higher numbers make a sharper underlying image
 * ASP (1>=ASP>=0): Weight power, lower numbers use more of the sharp image
 */
#ifdef LUMA_raw
#define AS 0
#define ASF 1.0
#define ASP 0.25
#else
#define AS 0
#define ASF 0.0
#define ASP 0.0
#endif

/* Weight discard
 *
 * Discard weights that fall below a threshold based on the average weight. 
 * This causes areas with less noise to receive less blur.
 * 
 * WD:
 * 	- 2: true average, very good quality, but slower and uses more memory
 * 	- 1: moving cumulative average, inaccurate, tends to blur directionally
 * 	- 0: disable
 *
 * WDT: Threshold coefficient, higher numbers discard more
 * WDP (WD=1): Higher numbers reduce the threshold more for small sample sizes
 */
#ifdef LUMA_raw
#define WD 1
#define WDT 0.875
#define WDP 6.0
#else
#define WD 1
#define WDT 0.875
#define WDP 6.0
#endif

/* Search shape
 *
 * Useful for making searches with areas between 1x1, 3x3, 5x5, etc. for
 * fine-grain control. Might have other effects too, such as directional blur 
 * for asymmetrical shapes. Each shape reduces search area in comparison to 
 * square.
 *
 * PS applies applies to patches, RS applies to research zones.
 *
 * 0: square (symmetrical)
 * 1: horizontal line
 * 2: vertical line
 * 3: diamond (symmetrical)
 * 4: triangle (pointing upward, center pixel is in the bottom-middle)
 * 5: truncated triangle (last row halved)
 * 6: offset square (accepts even and odd sizes)
 */
#ifdef LUMA_raw
#define RS 3
#define PS 4
#else
#define RS 3
#define PS 4
#endif

/* Rotational invariance
 *
 * Number of rotations to try for each patch comparison. Slow, but improves 
 * feature preservation, although greater rotations give diminishing returns.
 *
 * The angle in degrees of each rotation is 360/(RI+1), so RI=1 will do a 
 * single 180 degree rotation, RI=3 will do three 90 degree rotations, etc.
 */
#ifdef LUMA_raw
#define RI 0
#else
#define RI 0
#endif

/* Temporal denoising
 *
 * Limitations:
 * 	- Slower, since each frame is researched
 * 	- Requires gpu-next and nlmeans_next.glsl
 * 	- Luma-only (this is a bug)
 * 	- Max 3840x3840 resolution, limit can be increased at the bottom of the shader
 * 	- Max 10 frames, also hardcoded
 * 	- Might be buggy
 *
 * Gather samples across multiple frames. May cause motion blur and may 
 * struggle more with noise that persists across multiple frames, but can work 
 * very well on high quality video.
 *
 * For the spatial kernel, the distortion (SD) is a coefficient of the 
 * coordinates, with each component corresponding to an axis (X, Y, Z). For 
 * example:
 * 	- SD=(1,1,1): no distortion
 * 	- SD=(1,1,2): previous frames are twice as far away
 * 	- SD=(1,1,0.5): previous frames are half as far away
 * 	- SD=(1,1,0): previous frames are no further than the current frame
 *
 * SD is most useful for controlling motion blur, higher Z values produce less 
 * motion blur. SD only works if SS is greater than zero.
 *
 * The X and Y distortion of the spatial kernel can be controlled with SD too,
 * although I'm not aware of any practical use for them.
 *
 * T: number of frames used
 * SD: spatial distortion
 */
#ifdef LUMA_raw
#define T 0
#define SD vec3(1,1,1)
#else
#define T 0
#define SD vec3(1,1,1)
#endif

/* Extremes preserve
 *
 * Reduces denoising around very bright/dark areas. The downscaling factor of 
 * EP_LUMA (located near the top of this shader) controls the area sampled for 
 * luminance (higher numbers consider more area).
 *
 * EP: 1 to enable, 0 to disable
 * DP (starts at 1): EP strength on dark patches, 0 to fully denoise
 * BP (starts at 1): EP strength on bright patches, 0 to fully denoise
 */
#ifdef LUMA_raw
#define EP 1
#define BP 3.0
#define DP 1.0
#endif

/* Robust filtering
 *
 * Compares the pixel of interest against downscaled pixels.
 *
 * This will virtually always improves quality.
 *
 * The downscale factor can be modified in the WIDTH/HEIGHT directives for the 
 * DOWNSCALED (for CHROMA, RGB) and DOWNSCALED_LUMA (LUMA only) textures near 
 * the top of this shader, higher numbers increase blur.
 *
 * Any notation of RF as a positive number should be assumed to be referring to 
 * the downscaling factor, e.g., RF=3 means RF is enabled and the downscaling 
 * factor is set to 3.
 */
#ifdef LUMA_raw
#define RF 0
#else
#define RF 1
#endif

/* Estimator
 *
 * 0: means
 * 1: Euclidean medians (extremely slow, best for heavy noise)
 * 2: weight map (not a denoiser, intended for development use)
 * 3: weighted median intensity (slow, good for heavy noise)
 */
#ifdef LUMA_raw
#define M 0
#else
#define M 0
#endif

/* Blur factor
 *
 * The amount to blur the pixel of interest with the estimated pixel. For the 
 * means estimator this should always be 1.0, since it already blurs against 
 * the pixel of interest and the level of blur can be controlled with the S 
 * macro.
 *
 * BF (1>=BF>=0): blur factor, 1 being the estimation, 0 being the raw input
 */
#ifdef LUMA_raw
#define BF 1.0
#else
#define BF 1.0
#endif

/* Shader code */

#if RF && defined(LUMA_raw)
#define TEX DOWNSCALED_LUMA_tex
#elif RF
#define TEX DOWNSCALED_tex
#else
#define TEX HOOKED_tex
#endif

const int hp = P/2;
const int hr = R/2;

// rotation
#define ROTX(p) (cos(radians(ri)) * p.x - sin(radians(ri)) * p.y)
#define ROTY(p) (sin(radians(ri)) * p.y + cos(radians(ri)) * p.x)
#define ROT(p) vec3(ROTX(p), ROTY(p), p.z)

// search shapes and their corresponding areas
#define S_1X1(z,hz) for (z = vec3(0); z.x <= 0; z.x++)
#define S_1X1_A(hz,Z) 1

#define S_TRIANGLE(z,hz) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz); z.x++)
#define S_TRUNC_TRIANGLE(z,hz) for (z.y = -hz; z.y <= 0; z.y++) for (z.x = -abs(abs(z.y) - hz); z.x <= abs(abs(z.y) - hz)*int(z.y!=0); z.x++)
#define S_TRIANGLE_A(hz,Z) int(pow(hz, 2)+Z)

#define S_DIAMOND(z,hz) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -abs(abs(z.x) - hz); z.y <= abs(abs(z.x) - hz); z.y++)
#define S_DIAMOND_A(hz,Z) int(pow(hz, 2)*2+Z)

#define S_VERTICAL(z,hz) for (z.x = 0; z.x <= 0; z.x++) for (z.y = -hz; z.y <= hz; z.y++)
#define S_HORIZONTAL(z,hz) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = 0; z.y <= 0; z.y++)
#define S_LINE_A(hz,Z) Z

#define S_SQUARE(z,hz) for (z.x = -hz; z.x <= hz; z.x++) for (z.y = -hz; z.y <= hz; z.y++)
#define S_SQUARE_OFF(z,hz) for (z.x = 0; z.x <= hz; z.x++) for (z.y = 0; z.y <= hz; z.y++)
#define S_SQUARE_A(hz,Z) (Z*Z)

// research shapes
#define T1 (T+1)
#define FOR_FRAME for (r.z = 0; r.z < T1; r.z++)
#if R == 0 || R == 1
#define FOR_RESEARCH(r) FOR_FRAME S_1X1(r,hr)
const int r_area = S_1X1_A(hr,R)*T1;
#elif RS == 6
#define FOR_RESEARCH(r) FOR_FRAME S_SQUARE_OFF(r,hr)
const int r_area = S_SQUARE_A(hr,R)*T1;
#elif RS == 5
#define FOR_RESEARCH(r) FOR_FRAME S_TRUNC_TRIANGLE(r,hr)
const int r_area = S_TRIANGLE_A(hr,hr)*T1;
#elif RS == 4
#define FOR_RESEARCH(r) FOR_FRAME S_TRIANGLE(r,hr)
const int r_area = S_TRIANGLE_A(hr,R)*T1;
#elif RS == 3
#define FOR_RESEARCH(r) FOR_FRAME S_DIAMOND(r,hr)
const int r_area = S_DIAMOND_A(hr,R)*T1;
#elif RS == 2
#define FOR_RESEARCH(r) FOR_FRAME S_VERTICAL(r,hr)
const int r_area = S_LINE_A(hr,R)*T1;
#elif RS == 1
#define FOR_RESEARCH(r) FOR_FRAME S_HORIZONTAL(r,hr)
const int r_area = S_LINE_A(hr,R)*T1;
#elif RS == 0 && R == 2 // interpolated 2x2
#define FOR_RESEARCH(r) FOR_FRAME S_SQUARE(r,0.5)
const int r_area = 4*T1;
#elif RS == 0
#define FOR_RESEARCH(r) FOR_FRAME S_SQUARE(r,hr)
const int r_area = S_SQUARE_A(hr,R)*T1;
#endif

// patch shapes
#define RI1 (RI+1)
#define FOR_ROTATION for (float ri = 0; ri < 360; ri+=360.0/RI1)
#if P == 0 || P == 1
#define FOR_PATCH(p) S_1X1(p,hp) for (float ri = 0; ri <= 0; ri++)
const int p_area = S_1X1_A(hp,P)*RI1;
#elif PS == 6
#define FOR_PATCH(p) S_SQUARE_OFF(p,hp) FOR_ROTATION
const int p_area = S_SQUARE_A(hp,P)*RI1;
#elif PS == 5
#define FOR_PATCH(p) S_TRUNC_TRIANGLE(p,hp) FOR_ROTATION
const int p_area = S_TRIANGLE_A(hp,hp)*RI1;
#elif PS == 4
#define FOR_PATCH(p) S_TRIANGLE(p,hp) FOR_ROTATION
const int p_area = S_TRIANGLE_A(hp,P)*RI1;
#elif PS == 3
#define FOR_PATCH(p) S_DIAMOND(p,hp) FOR_ROTATION
const int p_area = S_DIAMOND_A(hp,P)*RI1;
#elif PS == 2
#define FOR_PATCH(p) S_VERTICAL(p,hp) FOR_ROTATION
const int p_area = S_LINE_A(hp,P)*RI1;
#elif PS == 1
#define FOR_PATCH(p) S_HORIZONTAL(p,hp) FOR_ROTATION
const int p_area = S_LINE_A(hp,P)*RI1;
#elif PS == 0 && P == 2 // interpolated 2x2
#define FOR_PATCH(p) S_SQUARE(p,0.5) FOR_ROTATION
const int p_area = 4*RI1;
#elif PS == 0
#define FOR_PATCH(p) S_SQUARE(p,hp) FOR_ROTATION
const int p_area = S_SQUARE_A(hp,P)*RI1;
#endif

const float r_scale = 1.0/r_area;
const float p_scale = 1.0/p_area;

#if T
vec4 load(vec3 off)
{
	switch (int(off.z)) {
	case 0:  return TEX(HOOKED_pos + HOOKED_pt * vec2(off));
	case 1:  return imageLoad(PREV1,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV1))));
	case 2:  return imageLoad(PREV2,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV2))));
	case 3:  return imageLoad(PREV3,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV3))));
	case 4:  return imageLoad(PREV4,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV4))));
	case 5:  return imageLoad(PREV5,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV5))));
	case 6:  return imageLoad(PREV6,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV6))));
	case 7:  return imageLoad(PREV7,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV7))));
	case 8:  return imageLoad(PREV8,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV8))));
	case 9:  return imageLoad(PREV9,  ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV9))));
	case 10: return imageLoad(PREV10, ivec2(round((HOOKED_pos + HOOKED_pt * vec2(off)) * imageSize(PREV10))));
	}
}
#else
#define load(off) TEX(HOOKED_pos + HOOKED_pt * vec2(off))
#endif

vec4 hook()
{
	vec3 r = vec3(0);
	vec3 p = vec3(0);
	int r_index = 0;
	vec4 total_weight = vec4(1);
	vec4 sum = HOOKED_texOff(0);
	vec4 result = vec4(0);

#if WD == 2 || M == 3
	vec4 all_weights[r_area];
	vec4 all_pixels[r_area];
#elif WD == 1
	vec4 no_weights = vec4(1);
#endif

#if M == 1
	vec4 minsum = vec4(0);
#endif

#if EP
	vec4 l = EP_LUMA_texOff(0);
	vec4 ep_weight = pow(min(1-l, l)*2, step(l, vec4(0.5))*DP + step(vec4(0.5), l)*BP);
#endif

	FOR_RESEARCH(r) {
		// low pdiff -> high weight, high weight -> more blur
		const float h = S*0.013;
		const float pdiff_scale = 1.0/(h*h);

		vec4 pdiff_sq = vec4(0);
#if defined(LUMA_gather) && P == 3 && PS == 4 && RF == 0 && RI == 0 && T == 0
		const ivec2 offsets[4] = {ivec2(0,-1), ivec2(-1,0), ivec2(0,0), ivec2(1,0)};
		#define gather(pos) (LUMA_mul * vec4(textureGatherOffsets(LUMA_raw, pos, offsets)))
		pdiff_sq.x = dot(pow(gather(HOOKED_pos) - gather(HOOKED_pos+r.xy*HOOKED_pt), vec4(2)), vec4(1));
#elif defined(LUMA_gather) && P == 2 && PS == 6 && RF == 0 && RI == 0 && T == 0
		pdiff_sq.x = dot(pow(LUMA_gather(HOOKED_pos, 0) - LUMA_gather(HOOKED_pos+r.xy*HOOKED_pt, 0), vec4(2)), vec4(1));
#else
		FOR_PATCH(p)
			pdiff_sq += pow(HOOKED_texOff(p) - load(ROT(p)+r), vec4(2));
#endif
		vec4 weight = exp(-pdiff_sq * p_scale * pdiff_scale);

		weight *= exp(-pow(length(r*SD) * SS, 2));

#if EP
		weight *= ep_weight;
#endif

#if WD == 2 || M == 3 // true average, weighted median intensity
		all_weights[r_index] = weight;
		all_pixels[r_index] = load(r);
		r_index++;
#elif WD == 1 // cumulative moving average
		// XXX maybe keep early samples in a small buffer?
		vec4 wd_scale = 1.0/no_weights;
		vec4 keeps = step(total_weight*wd_scale*WDT*exp(-wd_scale*WDP), weight);
		weight *= keeps;
		no_weights += keeps;
#endif

		sum += load(r) * weight;
		total_weight += weight;

#if M == 1 // Euclidean median
		// Based on: https://arxiv.org/abs/1207.3056
		vec3 r2;
		vec4 wpdist_sum = vec4(0);
		FOR_RESEARCH(r2) {
			vec4 pdist = vec4(0);
			FOR_PATCH(p)
				pdist += pow(load(p+r) - load(ROT(p)+r2), vec4(2));
			wpdist_sum += sqrt(pdist) * (1-weight);
		}

		// initialize minsum and result
		minsum += step(minsum, vec4(0)) * wpdist_sum;
		result += step(result, vec4(0)) * load(r);

		// find new minimums, exclude zeros
		vec4 newmin = step(wpdist_sum, minsum) - step(wpdist_sum, vec4(0));
		vec4 notmin = 1 - newmin;

		// update minimums
		minsum = (newmin * wpdist_sum) + (notmin * minsum);
		result = (newmin * load(r))    + (notmin * result);
#endif
	}

	vec4 avg_weight = total_weight * r_scale;

#if T
	imageStore(PREV10, ivec2(round(HOOKED_pos*imageSize(PREV10))), load(vec3(0,0,9)));
	imageStore(PREV9,  ivec2(round(HOOKED_pos*imageSize(PREV9))),  load(vec3(0,0,8)));
	imageStore(PREV8,  ivec2(round(HOOKED_pos*imageSize(PREV8))),  load(vec3(0,0,7)));
	imageStore(PREV7,  ivec2(round(HOOKED_pos*imageSize(PREV7))),  load(vec3(0,0,6)));
	imageStore(PREV6,  ivec2(round(HOOKED_pos*imageSize(PREV6))),  load(vec3(0,0,5)));
	imageStore(PREV5,  ivec2(round(HOOKED_pos*imageSize(PREV5))),  load(vec3(0,0,4)));
	imageStore(PREV4,  ivec2(round(HOOKED_pos*imageSize(PREV4))),  load(vec3(0,0,3)));
	imageStore(PREV3,  ivec2(round(HOOKED_pos*imageSize(PREV3))),  load(vec3(0,0,2)));
	imageStore(PREV2,  ivec2(round(HOOKED_pos*imageSize(PREV2))),  load(vec3(0,0,1)));
	imageStore(PREV1,  ivec2(round(HOOKED_pos*imageSize(PREV1))),  load(vec3(0)));
#endif

#if WD == 2 // true average
	total_weight = vec4(1);
	sum = HOOKED_texOff(0);

	for (int i = 0; i < r_area; i++) {
		vec4 keeps = step(avg_weight*WDT, all_weights[i]);
		all_weights[i] *= keeps;
		sum += all_pixels[i] * all_weights[i];
		total_weight += all_weights[i];
	}
#endif

#if M == 3 // weighted median intensity
	const float hr_area = r_area/2;
	vec4 is_median, gt, lt, gte, lte, neq;

	for (int i = 0; i < r_area; i++) {
		gt = lt = vec4(0);
		for (int j = 0; j < r_area; j++) {
			gte = step(all_pixels[i]*all_weights[i], all_pixels[j]*all_weights[j]);
			lte = step(all_pixels[j]*all_weights[j], all_pixels[i]*all_weights[i]);
			neq = 1 - gte * lte;
			gt += gte * neq;
			lt += lte * neq;
		}
		is_median = step(gt, vec4(hr_area)) * step(lt, vec4(hr_area));
		result += step(result, vec4(0)) * is_median * all_pixels[i];
	}
#elif M == 2 // weight map
	result = avg_weight;
#elif M == 0 // mean
	result = sum / total_weight;
#endif

#if AS // adaptive sharpening
	vec4 sharpened = HOOKED_texOff(0) + (HOOKED_texOff(0) - result) * ASF;
	vec4 sharpening_power = pow(avg_weight, vec4(1.0/(ASF*ASP)));
#endif
#if AS == 1 // denoised
	result = mix(sharpened, result, sharpening_power);
#elif AS == 2 // noisy
	result = mix(sharpened, HOOKED_texOff(0), sharpening_power);
#endif

	return mix(HOOKED_texOff(0), result, BF);
}

//!TEXTURE PREV1
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV2
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV3
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV4
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV5
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV6
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV7
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV8
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV9
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

//!TEXTURE PREV10
//!SIZE 3840 3840
//!FORMAT r32f
//!STORAGE

