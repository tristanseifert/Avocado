#!/bin/sh

#  mogenerator.sh
#  Avocado
#
#  Created by Tristan Seifert on 20160529.
#  Copyright © 2016 Tristan Seifert. All rights reserved.

/usr/local/bin/mogenerator --v2 --model ${SRCROOT}/ThumbHandler/CoreData/TSThumbCache.xcdatamodeld --machine-dir ${SRCROOT}/ThumbHandler/CoreData/Managed\ Object\ Subclasses/Entity --human-dir ${SRCROOT}/ThumbHandler/CoreData/Managed\ Object\ Subclasses/Model --includeh ${SRCROOT}/ThumbHandler/CoreData/Managed\ Object\ Subclasses/TSThumbCacheHumanModels.h