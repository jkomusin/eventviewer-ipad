
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

- (void)handleDragging:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)startDragging:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)initDraggingCellWithCell:(UITableViewCell*)cell AtOrigin:(CGPoint)point;
- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer;

@end
