## Original [Event Viewer](http://ivi.sagepub.com/content/7/2/133)
by Kate Beard, Heather Deese, Neal R. Pettigrew

## iPad Implementation
by Joshua R. Komusin
jkomusin@gmail.com

***
### Requirements:
* Mac OSX (last tested on version 10.7.3)
* XCode (last tested on version 4.3.2)
* iOS Development libraries for iOS (last tested on version 5.1)

***
### To Use:
Included is a standard .xcodeproj file that may be opened within XCode. Once this
has been opened, the application may be executed on the iOS Simulator as is. 

If you wish to deploy Event Viewer to a device, the app Bundle Identifier will 
need to be specified to a legal provisioning profile on the building machine.

More information on deploying iOS applications on devices may be found within 
the help pages of [Apple's iOS developer web portal](https://developer.apple.com/devcenter/ios).

*Note*: Currently a database is not referenced. You will need to provide your own
and modify any database connections to use the application.

***
### Details:
A demonstration video can be found [here](https://www.youtube.com/watch?v=o3lsqyPI1Rs).

The Event Viewer framework was originally implemented on a web-based interface.
This application is an exploration of porting desktop-oriented applications to
more constrained form factors, here a tablet.

In short, a selection of contraints on contiguous data streams are chosen which
specify what constitutes as an event (wind speed over 20 knots, for example).
These events are then sliced and diced based on a selection of constraints grouped
into either one, two, or three categories. These contraints may be anything from
timeframes (collected in 2004, in May, during the first half of the lunar cycle,
during a music festival), to location (Gulf of Maine, Buoy 207, Manhattan), to
type of event (high wind speed, ice-out dates on Lake Winnipesaukee, robberies).

If only one category is populated, "bands" will be displayed: simple timelines
of each event matching the constraint for that particular band.

If two categories are populated, bands will be grouped into "stacks". Each stack
is a set of bands. Each band is contrained by its own constraint as well as the
constraint of the stack it is grouped into.

If three cateogies are populated, stacks will be grouped into "panels". Each panel
is a set of stacks. Each stack is contrained by its own contraint as well as the
constraint of the panel it is grouped into.

By arranging bands into stacks and panels, transitioning from one band to another
in the same stack, the matching band in another stack, or the matching band in the
matching stack in another panel allows comparison between timelines by a single
variable.

This grouping allows for a large array of timelines to be assembled and compared
a la [Tufte's small multiples](http://en.wikipedia.org/wiki/Small_multiple).

***
### Additional Credits:
Matt Legend Gemmell - original author of MGSplitViewController which was integral
in getting this project up and running quickly.

