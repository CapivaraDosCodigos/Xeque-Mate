shader_type canvas_item;

uniform sampler2D palette : source_color;

uniform int match_mode : hint_enum(
	"HSV",
	"OKLab",
	"RGB",
	"RGB ponderado (redmean)",
	"Luminância",
	"CIELAB (dE76)",
	"CIE94",
	"CIEDE2000",
	"OKLCH ponderado",
	"HSL (matiz por saturação)",
	"YCbCr"
) = 0;

// Converte sRGB -> linear antes de OKLab / CIELAB / CIE94 / CIEDE2000 / OKLCH.
// Se o resultado parecer errado, desligue.
uniform bool input_is_srgb = true;

// Peso da luminosidade em OKLab e CIELAB (1.0 = distância normal).
uniform float lightness_weight : hint_range(0.0, 4.0) = 1.0;

// Pesos (luminosidade, croma, matiz) do modo OKLCH ponderado.
uniform vec3 lch_weights = vec3(1.0, 1.0, 1.0);

// Peso do Y (luma) no modo YCbCr.
uniform float luma_weight : hint_range(0.0, 8.0) = 1.0;


// ---------------------------------------------------------------- Conversões

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

vec3 to_linear(vec3 c) {
	return input_is_srgb ? srgb_to_linear(c) : c;
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

	vec4 p = mix(
		vec4(c.bg, K.wz),
		vec4(c.gb, K.xy),
		step(c.b, c.g)
	);

	vec4 q = mix(
		vec4(p.xyw, c.r),
		vec4(c.r, p.yzx),
		step(p.x, c.r)
	);

	float d = q.x - min(q.w, q.y);
	float e = 1e-10;

	return vec3(
		abs(q.z + (q.w - q.y) / (6.0 * d + e)),
		d / (q.x + e),
		q.x
	);
}

vec3 rgb_to_hsl(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	float l = (mx + mn) * 0.5;
	float s = d / (1.0 - abs(2.0 * l - 1.0) + 1e-10);

	return vec3(rgb_to_hsv(c).x, s, l);
}

// Matrizes escritas por colunas (o GLSL é column-major), então "m * v" está correto.
vec3 rgb_to_oklab(vec3 c) {
	mat3 m1 = mat3(
		vec3(0.4122214708, 0.2119034982, 0.0883024619),
		vec3(0.5363325363, 0.6806995451, 0.2817188376),
		vec3(0.0514459929, 0.1073969566, 0.6299787005)
	);

	mat3 m2 = mat3(
		vec3(0.2104542553, 1.9779984951, 0.0259040371),
		vec3(0.7936177850, -2.4285922050, 0.7827717662),
		vec3(-0.0040720468, 0.4505937099, -0.8086757660)
	);

	vec3 lms = m1 * to_linear(c);
	lms = pow(max(lms, vec3(0.0)), vec3(1.0 / 3.0));

	return m2 * lms;
}

vec3 rgb_to_lab(vec3 c) {
	mat3 m = mat3(
		vec3(0.4124564, 0.2126729, 0.0193339),
		vec3(0.3575761, 0.7151522, 0.1191920),
		vec3(0.1804375, 0.0721750, 0.9503041)
	);

	vec3 xyz = m * to_linear(c);
	vec3 n = max(xyz / vec3(0.95047, 1.0, 1.08883), vec3(0.0));

	vec3 f = mix(
		(903.3 * n + 16.0) / 116.0,
		pow(n, vec3(1.0 / 3.0)),
		step(0.008856, n)
	);

	return vec3(
		116.0 * f.y - 16.0,
		500.0 * (f.x - f.y),
		200.0 * (f.y - f.z)
	);
}


// ---------------------------------------------------------------- Distâncias

float hue_distance(float h1, float h2) {
	float h = abs(h1 - h2);
	return min(h, 1.0 - h);
}

float hsv_distance(vec3 a, vec3 b) {
	vec3 ah = rgb_to_hsv(a);
	vec3 bh = rgb_to_hsv(b);

	float hue = hue_distance(ah.x, bh.x);

	return
		hue * hue * 4.0 +
		pow(ah.y - bh.y, 2.0) +
		pow(ah.z - bh.z, 2.0);
}

float hsl_distance(vec3 a, vec3 b) {
	vec3 ah = rgb_to_hsl(a);
	vec3 bh = rgb_to_hsl(b);

	// O matiz perde sentido em cores dessaturadas, então pesa pela menor saturação
	float hue = hue_distance(ah.x, bh.x);
	float hue_weight = min(ah.y, bh.y);

	return
		hue * hue * 4.0 * hue_weight +
		pow(ah.y - bh.y, 2.0) +
		pow(ah.z - bh.z, 2.0);
}

float oklab_distance(vec3 a, vec3 b) {
	vec3 d = rgb_to_oklab(a) - rgb_to_oklab(b);

	return sqrt(lightness_weight * d.x * d.x + d.y * d.y + d.z * d.z);
}

float oklch_distance(vec3 a, vec3 b) {
	vec3 oa = rgb_to_oklab(a);
	vec3 ob = rgb_to_oklab(b);

	float dL = oa.x - ob.x;
	float dC = length(oa.yz) - length(ob.yz);
	float dab2 = dot(oa.yz - ob.yz, oa.yz - ob.yz);
	float dH2 = max(dab2 - dC * dC, 0.0);

	return sqrt(
		lch_weights.x * dL * dL +
		lch_weights.y * dC * dC +
		lch_weights.z * dH2
	);
}

float rgb_distance(vec3 a, vec3 b) {
	return distance(a, b);
}

float redmean_distance(vec3 a, vec3 b) {
	float rm = (a.r + b.r) * 0.5;
	vec3 d = a - b;

	return sqrt(
		(2.0 + rm) * d.r * d.r +
		4.0 * d.g * d.g +
		(3.0 - rm) * d.b * d.b
	);
}

float luma_distance(vec3 a, vec3 b) {
	vec3 w = vec3(0.2126, 0.7152, 0.0722);

	return abs(dot(a, w) - dot(b, w));
}

float ycbcr_distance(vec3 a, vec3 b) {
	float ya = dot(a, vec3(0.299, 0.587, 0.114));
	float yb = dot(b, vec3(0.299, 0.587, 0.114));

	float cb = (a.b - ya) * 0.564 - (b.b - yb) * 0.564;
	float cr = (a.r - ya) * 0.713 - (b.r - yb) * 0.713;

	return sqrt(luma_weight * (ya - yb) * (ya - yb) + cb * cb + cr * cr);
}

float cielab_distance(vec3 a, vec3 b) {
	vec3 d = rgb_to_lab(a) - rgb_to_lab(b);

	return sqrt(lightness_weight * d.x * d.x + d.y * d.y + d.z * d.z);
}

float cie94_distance(vec3 a, vec3 b) {
	vec3 l1 = rgb_to_lab(a);
	vec3 l2 = rgb_to_lab(b);

	float dL = l1.x - l2.x;
	float c1 = length(l1.yz);
	float c2 = length(l2.yz);
	float dC = c1 - c2;
	float dab2 = dot(l1.yz - l2.yz, l1.yz - l2.yz);
	float dH2 = max(dab2 - dC * dC, 0.0);

	float sc = 1.0 + 0.045 * c1;
	float sh = 1.0 + 0.015 * c1;

	return sqrt(
		dL * dL +
		(dC / sc) * (dC / sc) +
		dH2 / (sh * sh)
	);
}

float hue_angle_deg(float b, float ap) {
	if (abs(b) < 1e-6 && abs(ap) < 1e-6) {
		return 0.0;
	}

	float h = degrees(atan(b, ap));

	if (h < 0.0) {
		h += 360.0;
	}

	return h;
}

float ciede2000_distance(vec3 a, vec3 b) {
	vec3 l1 = rgb_to_lab(a);
	vec3 l2 = rgb_to_lab(b);

	float c1 = length(l1.yz);
	float c2 = length(l2.yz);
	float cm7 = pow((c1 + c2) * 0.5, 7.0);
	float g = 0.5 * (1.0 - sqrt(cm7 / (cm7 + 6103515625.0))); // 25^7

	float ap1 = (1.0 + g) * l1.y;
	float ap2 = (1.0 + g) * l2.y;
	float cp1 = sqrt(ap1 * ap1 + l1.z * l1.z);
	float cp2 = sqrt(ap2 * ap2 + l2.z * l2.z);
	float hp1 = hue_angle_deg(l1.z, ap1);
	float hp2 = hue_angle_deg(l2.z, ap2);

	float dLp = l2.x - l1.x;
	float dCp = cp2 - cp1;

	float dhp = 0.0;
	if (cp1 * cp2 != 0.0) {
		dhp = hp2 - hp1;
		if (dhp > 180.0) {
			dhp -= 360.0;
		} else if (dhp < -180.0) {
			dhp += 360.0;
		}
	}

	float dHp = 2.0 * sqrt(cp1 * cp2) * sin(radians(dhp * 0.5));

	float Lbp = (l1.x + l2.x) * 0.5;
	float Cbp = (cp1 + cp2) * 0.5;

	float hbp = hp1 + hp2;
	if (cp1 * cp2 != 0.0) {
		if (abs(hp1 - hp2) <= 180.0) {
			hbp *= 0.5;
		} else if (hbp < 360.0) {
			hbp = (hbp + 360.0) * 0.5;
		} else {
			hbp = (hbp - 360.0) * 0.5;
		}
	}

	float T = 1.0
		- 0.17 * cos(radians(hbp - 30.0))
		+ 0.24 * cos(radians(2.0 * hbp))
		+ 0.32 * cos(radians(3.0 * hbp + 6.0))
		- 0.20 * cos(radians(4.0 * hbp - 63.0));

	float dTheta = 30.0 * exp(-pow((hbp - 275.0) / 25.0, 2.0));
	float cbp7 = pow(Cbp, 7.0);
	float Rc = 2.0 * sqrt(cbp7 / (cbp7 + 6103515625.0));

	float lm50 = (Lbp - 50.0) * (Lbp - 50.0);
	float Sl = 1.0 + 0.015 * lm50 / sqrt(20.0 + lm50);
	float Sc = 1.0 + 0.045 * Cbp;
	float Sh = 1.0 + 0.015 * Cbp * T;
	float Rt = -sin(radians(2.0 * dTheta)) * Rc;

	float tl = dLp / Sl;
	float tc = dCp / Sc;
	float th = dHp / Sh;

	return sqrt(max(tl * tl + tc * tc + th * th + Rt * tc * th, 0.0));
}

float color_distance(vec3 a, vec3 b) {
	if (match_mode == 0) {
		return hsv_distance(a, b);
	} else if (match_mode == 1) {
		return oklab_distance(a, b);
	} else if (match_mode == 2) {
		return rgb_distance(a, b);
	} else if (match_mode == 3) {
		return redmean_distance(a, b);
	} else if (match_mode == 4) {
		return luma_distance(a, b);
	} else if (match_mode == 5) {
		return cielab_distance(a, b);
	} else if (match_mode == 6) {
		return cie94_distance(a, b);
	} else if (match_mode == 7) {
		return ciede2000_distance(a, b);
	} else if (match_mode == 8) {
		return oklch_distance(a, b);
	} else if (match_mode == 9) {
		return hsl_distance(a, b);
	}

	return ycbcr_distance(a, b);
}


void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a == 0.0) {
		COLOR = tex;
	} else {
		int palette_size = textureSize(palette, 0).x;

		float best_distance = 1e20;
		vec4 best_color = tex;

		for (int i = 0; i < 4096; i++) {
			if (i >= palette_size) {
				break;
			}

			vec4 p = texelFetch(palette, ivec2(i, 0), 0);
			float d = color_distance(tex.rgb, p.rgb);

			if (d < best_distance) {
				best_distance = d;
				best_color = p;
			}
		}

		COLOR = vec4(best_color.rgb, tex.a);
	}
}
