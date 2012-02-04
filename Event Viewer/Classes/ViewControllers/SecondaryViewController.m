
#import "SecondaryViewController.h"
#import "PrimaryViewController.h"
#import "QueryBuilderView.h"
#import "QueryTree.h"
#import "Query.h"


@interface SecondaryViewController ()

- (void)addNavButtonsToTopTable;
- (void)upOneLevel;
- (void)upToRoot;

@end


@implementation SecondaryViewController
{
    MGSplitViewController *splitViewController;     // Master MGUISplitViewController
    PrimaryViewController *detailViewController;    // ViewController displayed in the "primary" view of the MGUISplitViewController
    
    QueryTree *_queryTree;                          // Data model for the constraint table
    
    UITableViewCell *_draggingCell;                 // Table cell currently being dragged, used as visually moving cell
}

@synthesize splitViewController = _splitViewController;
@synthesize detailViewController = _detailViewController;


#pragma mark -
#pragma mark View lifecycle

/**
 *  Init function called by views loaded in by Interface Builder.
 *  Initializes drag-and-drop recognizer.
 */
- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {        
        self.navigationBar.tintColor = [UIColor blackColor];
        
        _detailViewController.masterViewController = self;
            
        // Create initial table
        UITableViewController *newTable = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        newTable.tableView.delegate = self;
        newTable.title = @"Categories";
        newTable.clearsSelectionOnViewWillAppear = YES;
        [self pushViewController:newTable animated:NO];
        
        // Create gesture recognizer
        UIPanGestureRecognizer* dragGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        [dragGesture setMaximumNumberOfTouches:2];
        [dragGesture setMinimumNumberOfTouches:2];
        [self.view addGestureRecognizer:dragGesture];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake(320.0f, 600.0f);
}


- (void)initQueryTreeWithHandler:(DatabaseHandler *)dbHandler
{
    _queryTree = [[QueryTree alloc] initWithHandler:dbHandler];
    _queryTree.treeDelegate = self;
    UITableViewController *top = (UITableViewController *)self.topViewController;
    top.tableView.dataSource = _queryTree;
    top.title = [_queryTree getCurrentTitle];
}


#pragma mark -
#pragma mark Drag-and-drop Handling

/**
 *  Initial entry point for a drag-and-drop gesture related to dragging a tableCell "Meta".
 *  Deals with all actions occurring inside the PanGestureRecognizer.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)handleDragging:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch ([gestureRecognizer state]) 
    {
        case UIGestureRecognizerStateBegan:
            [self startDragging:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self doDrag:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self stopDragging:gestureRecognizer];
            break;
        default:
            break;
    }
}

/**
 *  Initialize the table cell for dragging
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)startDragging:(UIPanGestureRecognizer *)gestureRecognizer
{    
    CGPoint point = [gestureRecognizer locationInView:self.view];
    NSIndexPath* indexPath = [(UITableView *)self.topViewController.view indexPathForRowAtPoint:point];
    UITableViewCell* cell = [(UITableView *)self.topViewController.view cellForRowAtIndexPath:indexPath];
    if(cell != nil)
    {
        CGPoint cellRelative = [gestureRecognizer locationInView:cell];
        CGPoint origin = [gestureRecognizer locationInView:_detailViewController.view];
        origin.x -= cellRelative.x;
        origin.y -= cellRelative.y;
        
        [self initDraggingCellWithCell:cell AtOrigin:origin];
        cell.highlighted = NO;
    }
}

/**
 *  Initialize the temporary cell to be visually dragged across the screen.
 *
 *  cell is the table cell in the table view that has begun to be dragged.
 *  origin is the point representing the absolute origin of the point in the MGUISplitViewController.
 */
- (void)initDraggingCellWithCell:(UITableViewCell*)cell AtOrigin:(CGPoint)origin
{
    if(_draggingCell != nil)
    {
        [_draggingCell removeFromSuperview];
        _draggingCell = nil;
    }
    
    CGRect frame = CGRectMake(origin.x, origin.y, cell.frame.size.width + 20.0f, cell.frame.size.height + 20.0f);
    
    _draggingCell = [[UITableViewCell alloc] init];
    _draggingCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    _draggingCell.textLabel.text = cell.textLabel.text;
    _draggingCell.textLabel.textColor = cell.textLabel.textColor;
    _draggingCell.highlighted = YES;
    _draggingCell.frame = frame;
    _draggingCell.alpha = 0.8;

    [_detailViewController.view addSubview:_draggingCell];
}

/**
 *  Move the temporary _draggingCell to the new location specified by the gesture recognizer's new point.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer
{
    if(_draggingCell != nil)
    {
        CGPoint translation = [gestureRecognizer translationInView:[_draggingCell superview]];
        [_draggingCell setCenter:CGPointMake([_draggingCell center].x + translation.x,
                                           [_draggingCell center].y + translation.y)];
        
        [gestureRecognizer setTranslation:CGPointZero inView:[_draggingCell superview]];
    }
}

/**
 *  Handle the resulting location of the dragged table cell, depending on where hit-tests register.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([_detailViewController pointIsInsideScrubber:gestureRecognizer])
    {
        [_detailViewController addNewPanel];
    }
    
    if ([_detailViewController pointIsInsideBuilder:gestureRecognizer])
    {
        NSLog(@"Dropped inside query builder!");
    }
    
    [_draggingCell removeFromSuperview];
    _draggingCell = nil;
}


#pragma mark -
#pragma mark Table view navigation


/**
 *  Adds custom naviagtion buttons to the top table view in the stack
 */
- (void)addNavButtonsToTopTable
{
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] 
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemRewind 
                                 target:self action:@selector(upToRoot)];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                  target:self action:@selector(upOneLevel)];
    self.topViewController.navigationItem.rightBarButtonItem = rightItem;
    self.topViewController.navigationItem.leftBarButtonItem = leftItem;
}

/**
 *  Pops the top table off the stack (navigates backwards one level up the tree)
 */
- (void)upOneLevel
{
    [_queryTree drillUpOne];
    [self popViewControllerAnimated:YES];    
}

/**
 *  Pops all tables off the stack (navigates back to the root of the tree)
 */
- (void)upToRoot
{
    [_queryTree drillUpToRoot];
    [self popToRootViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view delegation


/**
 *  Fired when a row is selected in the query table
 */
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone)
    {
        return;
    }
    
    [_queryTree drillDownToIndex:indexPath.row];
    
    // Create new table
    UITableViewController *newTable = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    newTable.title = [_queryTree getCurrentTitle];
    newTable.tableView.dataSource = _queryTree;
    newTable.tableView.delegate = self;
    newTable.clearsSelectionOnViewWillAppear = YES;
    
    // Add loading indicator    
    CGRect progressF = CGRectMake(self.contentSizeForViewInPopover.width - 80.0f, // Put it next to the 'up to root' button
                                  0.0f, 
                                  44.0f, 
                                  44.0f);
    UIActivityIndicatorView *progress= [[UIActivityIndicatorView alloc] initWithFrame:progressF];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [progress startAnimating];
    [self.navigationBar addSubview:progress];
    
    [self pushViewController:newTable animated:YES];
    [self addNavButtonsToTopTable];
}


#pragma mark -
#pragma mark Query Tree delegation


- (void)treeDidUpdateData
{
    UITableView *tableView = ((UITableViewController *)self.topViewController).tableView;
    for (UIView *v in [self.navigationBar subviews])
    {
        if ([v isKindOfClass:[UIActivityIndicatorView class]])
        {
            [v removeFromSuperview];
        }
    }
    
    [tableView reloadData];
}


#pragma mark -
#pragma mark Misc


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Set to return 'NO' for landscape orientations to fix bug where loading the app in landscape would cause issues with popping the nav controller
    return (UIInterfaceOrientationIsPortrait(interfaceOrientation) ? YES : NO);
}


@end
