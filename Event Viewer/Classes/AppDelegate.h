
#import <UIKit/UIKit.h>
#import "QueryViewController.h"
#import "ContentViewController.h"
#import "MGSplitViewController.h"

@class QueryViewController;
@class ContentViewController;
@class MGSplitViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MGSplitViewController *splitViewController;
    QueryViewController *rootViewController;
    ContentViewController *detailViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) IBOutlet MGSplitViewController *splitViewController;
@property (nonatomic, strong) IBOutlet QueryViewController *rootViewController;
@property (nonatomic, strong) IBOutlet ContentViewController *detailViewController;

@end
