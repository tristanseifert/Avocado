//
//  ahd_interpolate_mod.h
//  
//
//  Created by Tristan Seifert on 20160506.
//
//

#ifndef ahd_interpolate_mod_h
#define ahd_interpolate_mod_h

#include <stdint.h>

#include "libraw.h"

/**
 * @param imageData Pointer to the libraw structure
 * @param image Image pointer, input
 */
void ahd_interpolate_mod(libraw_data_t *imageData, uint16_t (*image)[4]);

#endif /* ahd_interpolate_mod_h */
