//
//  lmmse_interpolate.h
//  Avocado
//
//  Created by Tristan Seifert on 20160507.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef lmmse_interpolate_h
#define lmmse_interpolate_h

#import <Foundation/Foundation.h>

/**
 * This class implements an LMSSE Bayer data interpolator. It's internally
 * parallelized to take advantage of multiprocessing in NSOperation. It is not,
 * however, safe to use this class from multiple threads at once; internal state
 * is static.
 */
@interface TSLMSSEInterpolator : NSObject

/**
 * Interpolates missing colour components in a Bayer image, using the LSMME
 * algorithm, as demonstrated by Wu-Zhang.
 *
 * @param data Pointer to the libraw structure
 * @param image Image pointer, input
 */
- (void) interpolateWithLibRaw:(void *) data andBuffer:(uint16_t (*)[4]) image;

@end

#endif /* lmmse_interpolate_h */
