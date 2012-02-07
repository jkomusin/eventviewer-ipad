
#import "AppDelegate.h"

@implementation AppDelegate
{

}

@synthesize window, splitViewController, secondaryViewController, primaryViewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Add the split view controller's view to the window and display.
    [window addSubview:splitViewController.view];
    [window makeKeyAndVisible];
	
    [primaryViewController setSecondaryViewController:secondaryViewController];
	[primaryViewController performSelector:@selector(loginToDefault) withObject:nil afterDelay:0];
	
	if (NO) { // whether to allow dragging the divider to move the split.
		splitViewController.splitWidth = 15.0; // make it wide enough to actually drag!
		splitViewController.allowsDraggingDivider = YES;
	}
	
    return YES;
}




@end

