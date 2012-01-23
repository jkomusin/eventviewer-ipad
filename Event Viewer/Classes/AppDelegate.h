
#import <UIKit/UIKit.h>
#import "SecondaryViewController.h"
#import "PrimaryViewController.h"
#import "MGSplitViewController.h"

@class SecondaryViewController;
@class PrimaryViewController;
@class MGSplitViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> 

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) IBOutlet MGSplitViewController *splitViewController;
@property (nonatomic, strong) IBOutlet SecondaryViewController *rootViewController;
@property (nonatomic, strong) IBOutlet PrimaryViewController *detailViewController;

@end
