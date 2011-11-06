
#import "QueryViewController.h"
#import "ContentViewController.h"
#import "QueryData.h"

@implementation QueryViewController


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
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
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
 *  Initial entry point for a drag-and-drop gesture.
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
    
    CGRect frame = CGRectMake(origin.x, origin.y, cell.frame.size.width, cell.frame.size.height);
    
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
    cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

/**
 *  Fired when a row is selected in the query table
 */
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row, initializing test data . . .");
    //when selected, create number of test panels and update view
    QueryData *newData = [[QueryData alloc] initTestWithPanels:indexPath.row];
    
    NSLog(@"Test data initialized!");
    _detailViewController.queryData = newData;
}


#pragma mark -
#pragma mark Memory management




@end
