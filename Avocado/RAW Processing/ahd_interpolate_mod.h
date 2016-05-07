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

/**
 * @param image Image pointer, input
 * @param width Image width
 * @param height Image height
 * @param filters filters property from libraw_iparams_t
 * @param rgb_cam rgb_cam field from libraw_colordata_t
 */
void ahd_interpolate_mod(ushort (*image)[4], int width, int height, int filters, float rgb_cam[3][4]);

#endif /* ahd_interpolate_mod_h */
