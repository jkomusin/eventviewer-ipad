//
//  RootViewController.h
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import <UIKit/UIKit.h>

@class ContentViewController;

@interface QueryViewController : UITableViewController {
    ContentViewController *detailViewController;
}

@property (nonatomic, retain) IBOutlet ContentViewController *detailViewController;

- (void)selectFirstRow;

@end
