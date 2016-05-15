//
//  interpolation_shared.h
//  
//
//  Created by Tristan Seifert on 20160507.
//
//

#ifndef interpolation_shared_h
#define interpolation_shared_h

// undefine any previous definitions of these macros
#undef MIN
#undef MAX
#undef SQR
#undef ABS
#undef LIM
#undef ULIM
#undef CLIP
#undef SWAP

/// define a bunch of shit
#define FORC(cnt) for (c=0; c < cnt; c++)
#define FORC3 FORC(3)
#define FORC4 FORC(4)
#define FORCC FORC(colors)

#define SQR(x) ((x)*(x))
#define ABS(x) (((int)(x) ^ ((int)(x) >> 31)) - ((int)(x) >> 31))
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define LIM(x,min,max) MAX(min,MIN(x,max))
#define ULIM(x,y,z) ((y) < (z) ? LIM(x,y,z) : LIM(x,z,y))
#define CLIP(x) LIM((int)(x),0,65535)
#define SWAP(a,b) { a=a+b; b=a-b; a=a-b; }

#define FC(row, col, filters) \
(filters >> ((((row) << 1 & 14) + ((col) & 1)) << 1) & 3)

/// some colour space constants
static const double xyz_rgb[3][3] = {
	{ 0.412453, 0.357580, 0.180423 },
	{ 0.212671, 0.715160, 0.072169 },
	{ 0.019334, 0.119193, 0.950227 }
};

/// XYZ to sRGB
static const double xyz_sRgb[3][3] = {
	{ 3.2404542, -1.5371385, -0.4985314},
	{-0.9692660, 1.8760108, 0.0415560},
	{0.0556434, -0.2040259, 1.0572252}
};

// sRGB
static const double rgb_rgb[3][3] = {
	{ 1,0,0 },
	{ 0,1,0 },
	{ 0,0,1 }
};

// Adobe RGB
static const double adobe_rgb[3][3] = {
	{ 0.715146, 0.284856, 0.000000 },
	{ 0.000000, 1.000000, 0.000000 },
	{ 0.000000, 0.041166, 0.958839 }
};

// Wide RGB?
static const double wide_rgb[3][3] = {
	{ 0.593087, 0.404710, 0.002206 },
	{ 0.095413, 0.843149, 0.061439 },
	{ 0.011621, 0.069091, 0.919288 }
};

// ProPhoto RGB
static const double prophoto_rgb[3][3] ={
	{ 0.529317, 0.330092, 0.140588 },
	{ 0.098368, 0.873465, 0.028169 },
	{ 0.016879, 0.117663, 0.865457 }
};

static const double (*out_rgb[])[3] = { rgb_rgb, adobe_rgb, wide_rgb, prophoto_rgb };
static const double out_gamma[][6] = {
	{ (1.f / 2.4f), 12.92 }, // sRGB
	{},
	{},
	{}
};

/**
 * I honestly have no fucking clue what this does but it seems required
 */
static inline int fcol(size_t row, size_t col, unsigned int filters, ushort top_margin, ushort left_margin) {
	static const char filter[16][16] = {
		{ 2,1,1,3,2,3,2,0,3,2,3,0,1,2,1,0 },
		{ 0,3,0,2,0,1,3,1,0,1,1,2,0,3,3,2 },
		{ 2,3,3,2,3,1,1,3,3,1,2,1,2,0,0,3 },
		{ 0,1,0,1,0,2,0,2,2,0,3,0,1,3,2,1 },
		{ 3,1,1,2,0,1,0,2,1,3,1,3,0,1,3,0 },
		{ 2,0,0,3,3,2,3,1,2,0,2,0,3,2,2,1 },
		{ 2,3,3,1,2,1,2,1,2,1,1,2,3,0,0,1 },
		{ 1,0,0,2,3,0,0,3,0,3,0,3,2,1,2,3 },
		{ 2,3,3,1,1,2,1,0,3,2,3,0,2,3,1,3 },
		{ 1,0,2,0,3,0,3,2,0,1,1,2,0,1,0,2 },
		{ 0,1,1,3,3,2,2,1,1,3,3,0,2,1,3,2 },
		{ 2,3,2,0,0,1,3,0,2,0,1,2,3,0,1,0 },
		{ 1,3,1,2,3,2,3,2,0,2,0,1,1,0,3,0 },
		{ 0,2,0,3,1,0,0,1,1,3,3,2,3,2,2,1 },
		{ 2,1,3,2,3,1,2,1,0,3,0,2,0,2,0,2 },
		{ 0,3,1,0,0,2,0,3,2,1,3,1,1,3,1,3 }
	};
	
	if (filters == 1) return filter[(row+top_margin)&15][(col+left_margin)&15];
	
	// cut out support for Fuji X-Trans sensors for now
	//	if (filters == 9) return xtrans[(row+6) % 6][(col+6) % 6];
	
	return FC(row, col, filters);
}

#endif /* interpolation_shared_h */
