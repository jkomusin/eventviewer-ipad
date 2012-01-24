
#import "SecondaryViewController.h"
#import "PrimaryViewController.h"
#import "QueryBuilderView.h"
#import "Query.h"

@implementation UINavigationBar (CustomImage)
- (void)drawRect:(CGRect)rect {
    self.backgroundColor = [UIColor blackColor];
}
@end

@implementation SecondaryViewController
{
    MGSplitViewController *splitViewController;     // Master MGUISplitViewController
    PrimaryViewController *detailViewController;    // ViewController displayed in the "primary" view of the MGUISplitViewController
    
    UITableViewCell *draggingCell;                  // Table cell currently being dragged, used as visually moving cell
    UINavigationBar *_naviBar;                      // Table navigation bar
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
    if ((self = [super initWithCoder:coder]))
    {        
        UIPanGestureRecognizer* dragGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        [dragGesture setMaximumNumberOfTouches:2];
        [dragGesture setMinimumNumberOfTouches:2];
        [self.view addGestureRecognizer:dragGesture];
        
		self.title = @"Select constraints:";
        
        // Initialize toolbar
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] 
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemRewind 
                                 target:self action:nil];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                      target:self action:nil];
        
        UINavigationItem* navItem = [[UINavigationItem alloc] init];
        navItem.leftBarButtonItem = leftItem;
        navItem.rightBarButtonItem = rightItem;
        navItem.title = @"Your title";
        
        UINavigationBar *naviBar = [[UINavigationBar alloc] init];
        naviBar.items = [NSArray arrayWithObject:navItem];
        naviBar.frame = CGRectMake(0.0f, 0.0f, 320.0f, 44.0f);
        naviBar.tintColor = [UIColor blackColor];
        [self.view addSubview:naviBar];
        [self.view bringSubviewToFront:naviBar];
        _naviBar = naviBar;
        
        // Reposition table to make space for navigation bar
        UIEdgeInsets inset = UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f);
        self.tableView.contentInset = inset;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0f, 600.0f);
    
//    // Reposition table to make space for navigation bar
//    UIEdgeInsets inset = UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f);
//    self.tableView.contentInset = inset;
}


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)selectFirstRow
{
//	if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
//		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
//		[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
//	}
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
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:point];
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
    if(draggingCell != nil)
    {
        [draggingCell removeFromSuperview];
        draggingCell = nil;
    }
    
    CGRect frame = CGRectMake(origin.x, origin.y, cell.frame.size.width + 20.0f, cell.frame.size.height + 20.0f);
    
    draggingCell = [[UITableViewCell alloc] init];
    draggingCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    draggingCell.textLabel.text = cell.textLabel.text;
    draggingCell.textLabel.textColor = cell.textLabel.textColor;
    draggingCell.highlighted = YES;
    draggingCell.frame = frame;
    draggingCell.alpha = 0.8;

    [_detailViewController.view addSubview:draggingCell];
}

/**
 *  Move the temporary draggingCell to the new location specified by the gesture recognizer's new point.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UIPanGestureRecognizer *)gestureRecognizer
{
    if(draggingCell != nil)
    {
        CGPoint translation = [gestureRecognizer translationInView:[draggingCell superview]];
        [draggingCell setCenter:CGPointMake([draggingCell center].x + translation.x,
                                           [draggingCell center].y + translation.y)];
        
        [gestureRecognizer setTranslation:CGPointZero inView:[draggingCell superview]];
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
    
    [draggingCell removeFromSuperview];
    draggingCell = nil;
}


#pragma mark -
#pragma mark Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 10;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Configure the cell.
    cell.textLabel.text = [NSString stringWithFormat:@"%d Panels", indexPath.row];
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

/**
 *  Fired when a row is selected in the query table
 */
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row, initializing test data (%d panels) . . .", indexPath.row);
    //when selected, create number of test panels and update view
    Query *newData = [[Query alloc] initTestWithPanels:indexPath.row];
    
    NSLog(@"Test data initialized!");
    _detailViewController.queryData = newData;
}

/**
 *  Fired whenever the table view is scrolled.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Keep the navigation bar pinned to the top of the tableview
    CGRect frame = _naviBar.frame;
    frame.origin.y = scrollView.contentOffset.y;
    _naviBar.frame = frame;
    [self.view bringSubviewToFront:_naviBar];
}



@end
