# Event Viewer
by Kate Beard, et. al.

## iPad Implementation
by Joshua R. Komusin
jkomusin@gmail.com

***
### Requirements:
* Mac OSX (tested on version 10.7.3)
* XCode (tested on version 4.3.2)
* iOS Development libraries for iOS (tested on version 5.1)  

***
### To Use:
Included is a standard .xcodeproj file that may be opened within XCode. One this has been opened, the application may be executed on the iOS Simulator as is.

If you wish to deploy Event Viewer to a device, the app Bundle Identifier will need to be specified to a legal provisioning profile on the building machine.

More information on deploying iOS applications on devices may be found within the help pages of Apple's iOS developer web portal at:

https://developer.apple.com/devcenter/ios

***
### Known Issues:
Aside from simple logic issues present in any beta codebase, there may be issues with drawing query results within the iOS Simulator on certain versions of Mac OSX. This is related to problems with the font families and their available sizes on OSX vs. iOS. To my knowledge this is never a problem when run on a physical device.

