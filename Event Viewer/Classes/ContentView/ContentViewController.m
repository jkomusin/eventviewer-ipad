
#import "ContentViewController.h"
#import "QueryViewController.h"
#import "QueryData.h"
#import "ContentScrollView.h"
#import "BandZoomView.h"
#import "BandDrawView.h"

@interface ContentViewController ()

@property (nonatomic, strong) UIPopoverController *popoverController;   // Controller of the query popover, implemented as part of the MGSplitViewController
- (void)configureView;

@end



@implementation ContentViewController
{
    // MGUISplitViewController private properties
	IBOutlet MGSplitViewController *splitController;
	IBOutlet UIBarButtonItem *toggleItem;
	IBOutlet UIBarButtonItem *verticalItem;
	IBOutlet UIBarButtonItem *dividerStyleItem;
	IBOutlet UIBarButtonItem *masterBeforeDetailItem;
    UIPopoverController *popoverController;
    UIToolbar *toolbar;
    id detailItem;
    UILabel *_detailDescriptionLabel;
    ///////
    
    UISlider *_panelScrubber;               // Scrubber at the bottom of the results window that controls the display of overlaid panels
    UIView *_scrubberBar;                   // Frame for the panelScrubber
    NSArray *_scrubberButtons;              // Immutable array of buttons to select which panels are statically overlaid
    NSArray *_panelOverlays;                // Immutable array of indexes of panels that are currently overlaid
                                            //  NOTE: This includes the current panel if it is overlaid!
    ContentScrollView *_contentScrollView;  // Scrolling container for the results of the query
    
    float _zoomScale;
}

@synthesize toolbar, popoverController, detailItem, _detailDescriptionLabel;
@synthesize queryData = _queryData;
@synthesize currentPanel = _currentPanel;


#pragma mark -
#pragma mark Initialization

/**
 *  We may initiaize here, as the view is always loaded into memory
 *
 *  NOTE: Because the view is loaded from a .nib, initially viewDidLoad is called twice in succession
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // panelScrubber
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
    
    // Button array
    NSArray *tmp = [[NSArray alloc] init];
    _scrubberButtons = tmp;
    
    // Overlay array
    NSArray *overlays = [[NSArray alloc] init];
    _panelOverlays = overlays;
    
    // Scroll view for content
    CGRect csvFrame = CGRectMake(0.0, 44.0, 768.0, 880.0);
    ContentScrollView *csv = [[ContentScrollView alloc] initWithFrame:csvFrame];
	[csv setDataDelegate:self];
    _contentScrollView = csv;
    [self.view addSubview:_contentScrollView];
    _contentScrollView.bandZoomView.bandDrawView.dataDelegate = self;
    
    // QueryData model
    QueryData *qdata = [[QueryData alloc] init];
    self.queryData = qdata;
    
    self.currentPanel = -1;
    
    _zoomScale = 1.0f;
}


#pragma mark -
#pragma mark QueryData

/**
 *  Overridden setter for the static query data model, so that necessary updates may be performed when a new query is submitted.
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
//    QueryData *oldValue = _queryData;
    _queryData = [queryData copy];
    ///////
    
    // Update display with new data
    int newPanelNum = _queryData.panelNum;
    if (newPanelNum > 0)
        self.currentPanel = 0;
    else
        self.currentPanel = -1;
    
    [self resizeSubviews];
    [_contentScrollView.bandZoomView.bandDrawView setNeedsDisplay];
    
    // Re-initialize scrubber
    [self initScrubber];
}


#pragma mark -
#pragma mark View Sizing

/**
 *  Called whenever a new query is submitted, to resize all of the content-displying subviews to their proper sizes.
 */
- (void)resizeSubviews
{
    [_contentScrollView resizeForStackNum:_queryData.stackNum bandNum:_queryData.bandNum];
}


#pragma mark -
#pragma mark Panel Control

/**
 *  Custom setter for _currentPanel.
 *  Overridden to update the panel scrubber slider and to inform the scroll view and all subviews to redraw the new panel.
 */
- (void)setCurrentPanel:(int)panelNum
{
    _currentPanel = panelNum;
    [_panelScrubber setValue:(float)panelNum animated:YES];
    [_contentScrollView switchToPanel:panelNum];
}

/**
 *  Initialize/re-initialize scrubber with the current data model.
 *  Should be called whenever the data model is changed, so that the UI accurately reflects the current query.
 */
- (void)initScrubber
{
    int panelNum = _queryData.panelNum;
    _panelScrubber.maximumValue = (panelNum > 0.0f ? (float)panelNum - 1.0f : 0.0f);
    if (_panelScrubber.value > _panelScrubber.maximumValue)
    {
        [_panelScrubber setValue:_panelScrubber.maximumValue animated:YES];
    }
    // Remove all buttons
    if (_scrubberButtons.count != panelNum)
    {
        for (UIButton *b in _scrubberButtons)
        {
            [b removeFromSuperview];
        }
    }
    // Remove all overlays
    NSArray *emptyOverlays = [[NSArray alloc] init];
    _panelOverlays = emptyOverlays;
    // New buttons
    UIImage* inactiveImg = [UIImage imageNamed:@"grey.png"];
    UIImage* activeImg = [UIImage imageNamed:@"blue.png"];
    NSMutableArray *butts = [[NSMutableArray alloc] init];   
    for (int i = 0; i < panelNum; i++)
    {
        CGRect frame;
        if (panelNum == 1)
            frame = CGRectMake(90.0f+(568.0f/2.0f)-50.0f, 
                                  50.0f, 
                                  100.0f, 
                                  20.0f);
        else
            frame = CGRectMake(90.0f+(568.0f/(panelNum-1.0f))*i-50.0f, 
                               50.0f, 
                               100.0f, 
                               20.0f);
        
        UIButton *newb = [[UIButton alloc] initWithFrame:frame];
        newb.opaque = YES;
        [newb setBackgroundImage:inactiveImg forState:UIControlStateNormal];
        [newb setBackgroundImage:activeImg forState:UIControlStateHighlighted];
        
        NSString *panelM = [(NSArray *)[_queryData.selectedMetas objectForKey:@"Panels"] objectAtIndex:i];
        [newb setTitle:panelM forState:UIControlStateNormal];
        
        newb.tag = i;
        [newb setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [newb addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [butts addObject:newb];
        [_scrubberBar addSubview:newb];
    }
    _scrubberButtons = butts;

    int roundVal = roundf((float)_panelScrubber.value);
    [_contentScrollView switchToPanel:roundVal];
}

/**
 *  Event fired every time the scrubber is moved and changes value.
 *  Should switch to a new panel only when there is a new value.
 *
 *  sender is the scrubber UISlider object
 */
- (void)scrubberMoved:(id)sender
{
    int roundVal = roundf((float)_panelScrubber.value);
    
    if (_currentPanel != roundVal)
    {
        self.currentPanel = roundVal;
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
    if ([b titleColorForState:UIControlStateNormal] == [UIColor blackColor])
    {   // Enable overlay
        UIImage* activeImg = [UIImage imageNamed:@"blue.png"];
        [b setBackgroundImage:activeImg forState:UIControlStateNormal];
        [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        NSMutableArray *overlays = [_panelOverlays mutableCopy];
        [overlays addObject:[NSNumber numberWithInt:b.tag]];
        _panelOverlays = overlays;
    }
    else
    {   // Disable overlay
        UIImage* inactiveImg = [UIImage imageNamed:@"grey.png"];
        [b setBackgroundImage:inactiveImg forState:UIControlStateNormal];
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        NSMutableArray *overlays = [_panelOverlays mutableCopy];
        [overlays removeObjectIdenticalTo:[NSNumber numberWithInt:b.tag]];
        _panelOverlays = overlays;
    }

    [_contentScrollView.bandZoomView.bandDrawView setNeedsDisplay];
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


#pragma mark -
#pragma mark Data delegation

/**
 *  Returns a COPY of the query data model, to keep things threadsafe.
 */
- (QueryData *)delegateRequestsQueryData
{
    return [_queryData copy];
}

/**
 *  Returns the currently viewed panel (0-indexed)
 */
- (int)delegateRequestsCurrentPanel
{
    return _currentPanel;
}

/**
 *  Returns a COPY of the array of indexes (0-indexed) of panels currently selected as overlays.
 */
- (NSArray *)delegateRequestsOverlays
{
    return [_panelOverlays copy];
}

/**
 *  Returns the current timescale of stacks
 */
- (int)delegateRequestsTimescale
{
    return _queryData.timeScale;
}


// MGUISplitViewController functions
#pragma mark -
#pragma mark Managing the detail item


// When setting the detail item, update the view and dismiss the popover controller if it's showing.
- (void)setDetailItem:(id)newDetailItem
{
    if (detailItem != newDetailItem) {
        detailItem = newDetailItem;
        
        // Update the view
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
		barButtonItem.title = @"Query";
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Care should be taken since iPad has 2 more device orientations besides 4 UIInterface Orientation, FaceUp and FaceDown which are invalid in our case
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIDeviceOrientationIsValidInterfaceOrientation(orientation)) 
    {
        UIInterfaceOrientation uiOrientation = (UIInterfaceOrientation)orientation;
        [self handleInterfaceRotationForOrientation:uiOrientation];
    }
}

/**
 *  Handle all resizing of content.
 */
- (void)handleInterfaceRotationForOrientation:(UIInterfaceOrientation)interfaceOrientation 
{

}

/**
 *  Internal orientation handlers.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
    [self handleInterfaceRotationForOrientation:toInterfaceOrientation];
}
// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [self handleInterfaceRotationForOrientation:interfaceOrientation];
    return YES;
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self configureView];
}




@end
