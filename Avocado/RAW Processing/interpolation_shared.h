//
//  interpolation_shared.h
//  
//
//  Created by Tristan Seifert on 20160507.
//
//

#ifndef interpolation_shared_h
#define interpolation_shared_h

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
