
#import "SecondaryViewController.h"
#import "MGSplitViewController.h"
#import "PrimaryViewController.h"
#import "UILongPressBackpackGestureRecognizer.h"
#import "QueryBuilderView.h"
#import "QueryTree.h"
#import "Query.h"


@interface SecondaryViewController ()
- (void)addNavButtonsToTopTable;
- (void)upOneLevel;
- (void)upToRoot;

- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)makeDraggingCellWithCell:(UITableViewCell*)cell atOrigin:(CGPoint)origin withRecognizer:(UILongPressGestureRecognizer *)recognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

@end


@implementation SecondaryViewController
{
    MGSplitViewController *splitViewController;     // Master MGUISplitViewController
    PrimaryViewController *detailViewController;    // ViewController displayed in the "primary" view of the MGUISplitViewController
    
    QueryTree *_queryTree;                          // Data model for the constraint table
}

@synthesize splitViewController = _splitViewController;
@synthesize detailViewController = _detailViewController;


#pragma mark -
#pragma mark View lifecycle

/**
 *  Init function called by views loaded in by Interface Builder.
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
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake(MG_DEFAULT_SPLIT_POSITION, 600.0f);
}

//- (void)viewDidAppear:(BOOL)animated
//{
//	[super viewDidAppear:animated];
//	UITableViewController *table = (UITableViewController *)self.topViewController;
//	[table.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//}


- (void)initQueryTreeWithHandler:(DatabaseHandler *)dbHandler
{
    _queryTree = [[QueryTree alloc] initWithHandler:dbHandler];
    _queryTree.treeDelegate = self;
    UITableViewController *top = (UITableViewController *)self.topViewController;
    top.tableView.dataSource = _queryTree;
    top.title = [_queryTree getCurrentTitle];
}


#pragma mark -
#pragma mark Drag-and-drop handling for table cells

/**
 *  Initial entry point for a drag-and-drop gesture related to dragging a tableCell "Meta".
 *  Deals with all actions occurring inside the LongPressGestureRecognizer.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)handleDragging:(UILongPressBackpackGestureRecognizer *)gestureRecognizer
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
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)startDragging:(UILongPressBackpackGestureRecognizer *)gestureRecognizer
{    
    UITableViewCell* cell = (UITableViewCell *)gestureRecognizer.view;
    cell.highlighted = NO;
    
    CGPoint origin = [gestureRecognizer locationInView:_detailViewController.view];
    
    [self makeDraggingCellWithCell:cell atOrigin:origin withRecognizer:gestureRecognizer];
}

/**
 *  Initialize the temporary cell to be visually dragged across the screen.
 *
 *  cell is the table cell in the table view that has begun to be dragged.
 *  origin is the point representing the absolute origin of the point in the MGUISplitViewController.
 */
- (void)makeDraggingCellWithCell:(UITableViewCell*)cell atOrigin:(CGPoint)origin withRecognizer:(UILongPressBackpackGestureRecognizer *)recognizer
{    
    static NSString *cellIdentifier = @"Constraint";    
    
    UITableViewCell *draggingCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    draggingCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    draggingCell.textLabel.text = cell.textLabel.text;
    draggingCell.textLabel.textColor = cell.textLabel.textColor;
    draggingCell.detailTextLabel.text = cell.detailTextLabel.text;
    draggingCell.detailTextLabel.textColor = cell.detailTextLabel.textColor;
    draggingCell.highlighted = YES;
    draggingCell.center = origin;
    draggingCell.alpha = 0.8f;
    draggingCell.tag = cell.tag;
    
    // Move current recognizer to this new cell, and add a new one to the old cell
    [draggingCell addGestureRecognizer:recognizer];
    [cell removeGestureRecognizer:recognizer];
	// Store reference to the old cell and Constraint in the recognizer
	UITableView *table = (UITableView *)[cell superview];
	NSArray *arr = [NSArray arrayWithObjects:cell, [_queryTree getConstraintAtIndex:[table indexPathForCell:cell].row], nil];
	recognizer.storage = arr;
	
    UILongPressBackpackGestureRecognizer* dragGesture = [[UILongPressBackpackGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
    [dragGesture setNumberOfTouchesRequired:1];
    [dragGesture setMinimumPressDuration:0.1f];
    [cell addGestureRecognizer:dragGesture];
    
    [_detailViewController.view addSubview:draggingCell];
}

/**
 *  Move the temporary _draggingCell to the new location specified by the gesture recognizer's new point.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UILongPressBackpackGestureRecognizer *)gestureRecognizer
{
    UITableViewCell *draggingCell = (UITableViewCell *)gestureRecognizer.view;

    [draggingCell setCenter:[gestureRecognizer locationInView:_detailViewController.view]];
}

/**
 *  Handle the resulting location of the dragged table cell, depending on where hit-tests register.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UILongPressBackpackGestureRecognizer *)gestureRecognizer
{
//    Constraint *c = [_queryTree getConstraintAtIndex:gestureRecognizer.view.tag];
	NSArray *arr = gestureRecognizer.storage;
	Constraint *c = (Constraint *)[arr objectAtIndex:1];
    
    if ([_detailViewController droppedViewWithGestureRecognizer:gestureRecognizer forConstraint:c])
	{
		// Remove constraint from tree
		UITableViewCell *cell = (UITableViewCell *)[arr objectAtIndex:0];
		UITableViewController *table = (UITableViewController *)self.topViewController;
		NSIndexPath *path = [table.tableView indexPathForCell:cell];
		[_queryTree removeContraintAtIndex:path.row];
		NSArray *array = [NSArray arrayWithObject:path];
		[table.tableView deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationAutomatic];
		[table.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}

    [(UITableViewCell *)gestureRecognizer.view removeFromSuperview];
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
        [cell setSelected:NO];
        return;
    }
    
    // Create new table
    UITableViewController *newTable = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    newTable.tableView.dataSource = _queryTree;
    newTable.tableView.delegate = self;
    newTable.title = cell.textLabel.text;
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
    
    [_queryTree drillDownToIndex:indexPath.row];
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

- (NSDictionary *)getSelectedMetas
{
	return _detailViewController.queryData.selectedMetas;
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
