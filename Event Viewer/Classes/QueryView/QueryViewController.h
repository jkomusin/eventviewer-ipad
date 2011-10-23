
#import <UIKit/UIKit.h>
#import "ContentViewController.h"

@class ContentViewController;

@interface QueryViewController : UITableViewController {
    ContentViewController *detailViewController;
}

@property (nonatomic, strong) IBOutlet ContentViewController *detailViewController;

- (void)selectFirstRow;

@end
