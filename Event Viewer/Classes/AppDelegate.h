//
//  MGSplitViewAppDelegate.h
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import <UIKit/UIKit.h>

@class QueryViewController;
@class ContentViewController;
@class MGSplitViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MGSplitViewController *splitViewController;
    QueryViewController *rootViewController;
    ContentViewController *detailViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet MGSplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet QueryViewController *rootViewController;
@property (nonatomic, retain) IBOutlet ContentViewController *detailViewController;

@end
