
#import <UIKit/UIKit.h>

@class MGSplitViewController;
@class PrimaryViewController;
@class DatabaseHandler;


/**
 *  Delegate protocol for the QueryTree to inform the table when refreshing is necessary
 */
@protocol TreeDelegate
@required
- (void)treeDidUpdateData;
- (void)handleDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

@end


/**
 *  "Secondary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the tree of queriable constraints.
 */
@interface SecondaryViewController : UINavigationController <UITableViewDelegate, TreeDelegate>

@property (nonatomic, strong) MGSplitViewController *splitViewController;
@property (nonatomic, strong) IBOutlet PrimaryViewController *detailViewController;

- (void)initQueryTreeWithHandler:(DatabaseHandler *)dbHandler;

@end
