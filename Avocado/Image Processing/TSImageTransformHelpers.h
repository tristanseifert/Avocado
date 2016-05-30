//
//  TSImageTransformHelpers.h
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

/**
 * Rotates and flips the given CGImage, according to the specified orientation
 * value; it is the same as the EXIF orientation tag.
 *
 * If this function fails (perhaps due to memory constraints, or an internal
 * library error,) it will return the input image.
 *
 * @param inImage Input image; this image is released upon successful completion
 * of all operations.
 * @param orientation An EXIF orientation value, in the range of [0, 7].
 *
 * @return The original image, if an error occurred, or a newly allocated image.
 */
CGImageRef TSFliptateImageWithEXIFOrientation(CGImageRef inImage, NSUInteger orientation);