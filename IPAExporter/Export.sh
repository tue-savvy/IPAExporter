#!/bin/sh

#  Export.sh
#  IPAExporter
#
#  Created by Tue Nguyen on 10/11/14.
#  Copyright (c) 2014 HOME. All rights reserved.

echo "*********************************"
echo "Build Started"
echo "*********************************"

echo "*********************************"
echo "Beginning Build Process"
echo "*********************************"

#xcodebuild -exportArchive -exportFormat ipa -archivePath "${1}" -exportPath "${2}" -exportProvisioningProfile "${3}" -exportSigningIdentity "${4}"
xcrun -sdk iphoneos PackageApplication -v "${1}" -o "${2}" --sign "${3}" --embed "${4}"


echo "*********************************"
echo "Creating IPA"
echo "*********************************"