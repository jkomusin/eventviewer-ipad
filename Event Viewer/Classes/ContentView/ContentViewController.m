
#import "ContentViewController.h"


@interface ContentViewController ()

@property (nonatomic, strong) UIPopoverController *popoverController;
- (void)configureView;

@end



@implementation ContentViewController

@synthesize toolbar, popoverController, detailItem, _detailDescriptionLabel;
@synthesize queryData = _queryData;


/**
 *  We may initiaize here, as the view is always loaded into memory
 *
 *  NOTE: Because the view is loaded from a .nib, initially viewDidLoad is called twice in succession
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //create QueryData model
    QueryData *qdata = [[QueryData alloc] init];
    _queryData = qdata;
    
    //create panelScrubber to navigate between panel overlays 
    CGRect scrubberBarFrame = CGRectMake(0.0, 924.0, 768.0, 100.0);
    UIView *scrubberBar = [[UIView alloc] initWithFrame:scrubberBarFrame];
    _scrubberBar = scrubberBar;
    _scrubberBar.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
    _scrubberBar.opaque = YES;
    CGRect scrubberFrame = CGRectMake(100.0, 0.0, 568.0, 50.0);
    UISlider *pscrub = [[UISlider alloc] initWithFrame:scrubberFrame];
    _panelScrubber = pscrub;
    [_panelScrubber addTarget:self action:@selector(scrubberMoved:) forControlEvents:UIControlEventValueChanged];
    [_panelScrubber addTarget:self action:@selector(scrubberStopped:) forControlEvents:UIControlEventTouchUpInside];
    UIImage* trackImage = [UIImage imageNamed:@"scrubber.png"];
    UIImage* useableTrackImage = [trackImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [_panelScrubber setMinimumTrackImage:useableTrackImage forState:UIControlStateNormal];
    [_panelScrubber setMaximumTrackImage:useableTrackImage forState:UIControlStateNormal];
    _panelScrubber.opaque = YES;
    _panelScrubber.continuous = YES;
    _panelScrubber.maximumValue = 0.0;
    _panelScrubber.minimumValue = 0.0;
    _panelScrubber.value = 0.0;
    [_scrubberBar addSubview:_panelScrubber];
    [self.view addSubview:_scrubberBar];
    
    //initialize empty button array
    NSArray *tmp = [[NSArray alloc] init];
    _scrubberButtons = tmp;
    
    //create scroll view for content
    CGRect csvFrame = CGRectMake(0.0, 44.0, 768.0, 880.0);
    ContentScrollView *csv = [[ContentScrollView alloc] initWithFrame:csvFrame];
    _contentScrollView = csv;
    [self.view addSubview:_contentScrollView];
}


#pragma mark -
#pragma mark QueryData

/**
 *  Overridden setter for the static query data model, so that necessary updates may be performed when a new query is created.
 *  Implements the 'copy' property descriptor for thread-safety.
 *
 *  queryData is the new data model object
 */
- (void)setQueryData:(QueryData *)queryData
{
    // Copy protocol
    if (_queryData == queryData)
    {
        return;
    }
    QueryData *oldValue = _queryData;
    _queryData = [queryData copy];
    ///////
    
    //update display with new data
    int newPanelNum = _queryData.panelNum;
    int oldPanelNum = oldValue.panelNum;
    if (newPanelNum > oldPanelNum)
    {
        //add new panels
        for (int i = 0; i < newPanelNum - oldPanelNum; i++)
        {
            [_contentScrollView addPanelWithStacks:TEST_STACKS Bands:TEST_BANDS];
        }
    }
    else if (newPanelNum < oldPanelNum)
    {
        //remove excess panels
        for (int i = 0; i < oldPanelNum - newPanelNum; i++)
        {
            [_contentScrollView removePanel];
        }
    }
    
    //updated scrubber
    _panelScrubber.maximumValue = (newPanelNum > 0 ? (float)newPanelNum - 1 : 0);
    if (_panelScrubber.value > _panelScrubber.maximumValue)
    {   //set value to max if over max
        _panelScrubber.value = _panelScrubber.maximumValue;
    }
    if (_scrubberButtons.count != 0)    //remove old buttons
    {
        for (UIButton *b in _scrubberButtons)
        {
            [b removeFromSuperview];
        }
    }
    UIImage* inactiveImg = [UIImage imageNamed:@"x_inactive.png"];
    UIImage* activeImg = [UIImage imageNamed:@"x_active.png"];
    NSMutableArray *butts = [[NSMutableArray alloc] init]; 
    for (int i = 0; i < newPanelNum; i++)
    {   //create check boxes
        CGRect frame = CGRectMake(90.0+(568.0/(newPanelNum-1))*i, 
                                  50.0, 
                                  20.0, 
                                  20.0);
        UIButton *newb = [[UIButton alloc] initWithFrame:frame];
        newb.opaque = YES;
        [newb setBackgroundImage:inactiveImg forState:UIControlStateNormal];
        [newb setBackgroundImage:activeImg forState:UIControlStateHighlighted];
        newb.tag = i;
        //indicate button is initially disabled (Green == disabled, Red == enabled)
        [newb setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [newb addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [butts addObject:newb];
        [_scrubberBar addSubview:newb];
    }
    _scrubberButtons = butts;
    //show appropriate view
    int roundVal = roundf((float)_panelScrubber.value);
    [_contentScrollView switchToPanel:roundVal];
    NSLog(@"Switching to panel %d", roundVal);
}


#pragma mark -
#pragma mark Panel Scrubber Control

/**
 *  Event fired every time the scrubber is moved and changes value.
 *  Should switch to a new panel only when there is a new value.
 *
 *  sender is the scrubber UISlider object
 */
- (void)scrubberMoved:(id)sender
{
    int roundVal = roundf((float)_panelScrubber.value);
    if (_contentScrollView.currentPanel != roundVal)
    {
        [_contentScrollView switchToPanel:roundVal];
        NSLog(@"Switching to panel %d", roundVal);
    }
}

/**
 *  Event fired when the scrubber is released.
 *  Snaps the slider back to the nearest whole value, as the UISlider's value is internally a float.
 *  Never needs to update which panel is displayed, as the rouded value was calculated and updated when the slider changed to that value.
 *
 *  sender is the scrubber UISlider object
 */
- (void)scrubberStopped:(id)sender
{
    int roundVal = roundf((float)_panelScrubber.value);
    [_panelScrubber setValue:(float)roundVal animated:YES];
}

/**
 *  Event fired when a button to select a panel as statically overlaid is pressed.
 *
 *  sender is the button being pressed, which has the following properties set:
 *      'tag' property of the index of the panel it is associated with
 *      'titleColorForState:UIControlStateNormal' is the state of the button.
 *          [UIColor greenColor] indicates that it was disabled before the press
 *          [UIColor redColor] indicates the opposite
 */
- (void)buttonPressed:(id)sender
{
    UIButton *b = (UIButton *)sender;
    if ([b titleColorForState:UIControlStateNormal] == [UIColor greenColor])
    {
        UIImage* activeImg = [UIImage imageNamed:@"x_active.png"];
        [b setBackgroundImage:activeImg forState:UIControlStateNormal];
        [b setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    else
    {
        UIImage* inactiveImg = [UIImage imageNamed:@"x_inactive.png"];
        [b setBackgroundImage:inactiveImg forState:UIControlStateNormal];
        [b setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    }

    [_contentScrollView toggleOverlayPanel:b.tag];
}


#pragma mark -
#pragma mark Drag-and-drop functionality

/**
 *  Determines whether a point inside of the ContentViewController is within the bounds of the panel scrubber.
 *
 *  recognizer is the gesture recognizer pointing to a set of coordinates in the view,
 */
- (BOOL)pointIsInsideScrubber:(UIPanGestureRecognizer *)recognizer
{
    return [_scrubberBar pointInside:[recognizer locationInView:_scrubberBar] withEvent:nil];
}

/**
 *  Add a new panel to the array of panels in existence.
 */
- (void)addNewPanel
{
    int newPanelNum = _queryData.panelNum + 1;
    NSLog(@"New number of panels: %d", newPanelNum);
    QueryData *newData = [[QueryData alloc] initTestWithPanels:newPanelNum];
    self.queryData = newData;
}



// MGUISplitViewController functions
#pragma mark -
#pragma mark Managing the detail item


// When setting the detail item, update the view and dismiss the popover controller if it's showing.
- (void)setDetailItem:(id)newDetailItem
{
    if (detailItem != newDetailItem) {
        detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
	
    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }        
}


- (void)configureView
{
    // Update the user interface for the detail item.
    _detailDescriptionLabel.text = [detailItem description];
	toggleItem.title = ([splitController isShowingMaster]) ? @"Hide Master" : @"Show Master"; // "I... AM... THE MASTER!" Derek Jacobi. Gave me chills.
	verticalItem.title = (splitController.vertical) ? @"Horizontal Split" : @"Vertical Split";
	dividerStyleItem.title = (splitController.dividerStyle == MGSplitViewDividerStyleThin) ? @"Enable Dragging" : @"Disable Dragging";
	masterBeforeDetailItem.title = (splitController.masterBeforeDetail) ? @"Detail First" : @"Master First";
}


#pragma mark -
#pragma mark Split view support


- (void)splitViewController:(MGSplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController 
		  withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController: (UIPopoverController*)pc
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	
	if (barButtonItem) {
		barButtonItem.title = @"Popover";
		NSMutableArray *items = [[toolbar items] mutableCopy];
		[items insertObject:barButtonItem atIndex:0];
		[toolbar setItems:items animated:YES];
	}
    self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc 
	 willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	
	if (barButtonItem) {
		NSMutableArray *items = [[toolbar items] mutableCopy];
		[items removeObject:barButtonItem];
		[toolbar setItems:items animated:YES];
	}
    self.popoverController = nil;
}


- (void)splitViewController:(MGSplitViewController*)svc 
		  popoverController:(UIPopoverController*)pc 
  willPresentViewController:(UIViewController *)aViewController
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)splitViewController:(MGSplitViewController*)svc willChangeSplitOrientationToVertical:(BOOL)isVertical
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)splitViewController:(MGSplitViewController*)svc willMoveSplitToPosition:(float)position
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (float)splitViewController:(MGSplitViewController *)svc constrainSplitPosition:(float)proposedPosition splitViewSize:(CGSize)viewSize
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	return proposedPosition;
}


#pragma mark -
#pragma mark Actions


- (IBAction)toggleMasterView:(id)sender
{
	[splitController toggleMasterView:sender];
	[self configureView];
}


- (IBAction)toggleVertical:(id)sender
{
	[splitController toggleSplitOrientation:self];
	[self configureView];
}


- (IBAction)toggleDividerStyle:(id)sender
{
	MGSplitViewDividerStyle newStyle = ((splitController.dividerStyle == MGSplitViewDividerStyleThin) ? MGSplitViewDividerStylePaneSplitter : MGSplitViewDividerStyleThin);
	[splitController setDividerStyle:newStyle animated:YES];
	[self configureView];
}


- (IBAction)toggleMasterBeforeDetail:(id)sender
{
	[splitController toggleMasterBeforeDetail:sender];
	[self configureView];
}


#pragma mark -
#pragma mark Rotation support


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self configureView];
}




@end
