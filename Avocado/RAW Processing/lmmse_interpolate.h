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

/**
 * @param imageData Pointer to the libraw structure
 * @param image Image pointer, input
 * @param gamma_apply Whether gamma should be applied
 */
void lmmse_interpolate(libraw_data_t *imageData, uint16_t (*image)[4], int gamma_apply);

#endif /* lmmse_interpolate_h */
