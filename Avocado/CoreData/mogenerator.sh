#!/bin/sh

#  mogenerator.sh
#  Avocado
#
#  Created by Tristan Seifert on 20160428.
#  Copyright © 2016 Tristan Seifert. All rights reserved.

/usr/local/bin/mogenerator --v2 --model ${SRCROOT}/Avocado/CoreData/Avocado.xcdatamodeld --machine-dir ${SRCROOT}/Avocado/CoreData/Managed\ Object\ Subclasses/Entity --human-dir ${SRCROOT}/Avocado/CoreData/Managed\ Object\ Subclasses/Model --includeh ${SRCROOT}/Avocado/CoreData/Managed\ Object\ Subclasses/TSHumanModels.h

#--base-class OKManagedObject