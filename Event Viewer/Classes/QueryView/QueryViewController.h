
#import <UIKit/UIKit.h>

@class MGSplitViewController;
@class ContentViewController;

/**
 *  "Secondary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the tree of queriable constraints.
 */
@interface QueryViewController : UITableViewController 
{
    MGSplitViewController *splitViewController;     // Master MGUISplitViewController
    ContentViewController *detailViewController;    // ViewController displayed in the "primary" view of the MGUISplitViewController
    
    UITableViewCell *draggingCell;                  // Table cell currently being dragged, used as visually moving cell
}

@property (nonatomic, strong) MGSplitViewController *splitViewController;
@property (nonatomic, strong) IBOutlet ContentViewController *detailViewController;

- (void)selectFirstRow;

- (void)startDragging:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)initDraggingCellWithCell:(UITableViewCell*)cell AtOrigin:(CGPoint)point;
- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer;

@end
