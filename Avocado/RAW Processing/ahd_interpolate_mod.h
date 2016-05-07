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
 * @param image Image pointer, input
 * @param imageData Pointer to the libraw structure
 */
void ahd_interpolate_mod(uint16_t (*image)[4], libraw_data_t *imageData);

#endif /* ahd_interpolate_mod_h */
