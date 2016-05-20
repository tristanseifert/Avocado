//
//  TSLibraryImage+CoreImagePipeline.h
//  Avocado
//
//	Adds a helper method on the library image class to set up a CoreImage
//	pipeline job with the neccesary filters.
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryImage.h"

@class TSCoreImagePipelineJob;
@interface TSLibraryImage (CoreImagePipeline)

- (void) TSCIPipelineSetUpJob:(TSCoreImagePipelineJob *) job;

@end
