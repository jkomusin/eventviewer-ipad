
#import <UIKit/UIKit.h>
#import "ContentViewController.h"

@class ContentViewController;

/**
 *  "Secondary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the tree of queriable constraints.
 */
@interface QueryViewController : UITableViewController 
{
    ContentViewController *detailViewController;    // ViewController displayed in the "primary" view of the MGUISplitViewController
}

@property (nonatomic, strong) IBOutlet ContentViewController *detailViewController;

- (void)selectFirstRow;

@end
