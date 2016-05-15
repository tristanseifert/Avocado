//
//  lmmse_interpolate.h
//  Avocado
//
//  Created by Tristan Seifert on 20160507.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef lmmse_interpolate_h
#define lmmse_interpolate_h

#include <stdint.h>
#include "libraw.h"

#ifdef __cplusplus
extern "C" {
#endif
	
/**
 * Interpolates missing colour components in a Bayer image, using the LSMME
 * algorithm, as demonstrated by Wu-Zhang.
 *
 * @param imageData Pointer to the libraw structure
 * @param image Image pointer, input
 */
void lmmse_interpolate(libraw_data_t *imageData, uint16_t (*image)[4]);


#ifdef __cplusplus
}
#endif

#endif /* lmmse_interpolate_h */