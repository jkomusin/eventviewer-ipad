
#import "ContentViewController.h"
#import "QueryViewController.h"
#import "ContentScrollView.h"
#import "PanelZoomView.h"
#import "PanelDrawView.h"
#import "QueryData.h"
#import "Meta.h"

@interface ContentViewController ()

@property (nonatomic, strong) UIPopoverController *popoverController;   // Controller of the query popover, implemented as part of the MGSplitViewController
- (void)configureView;

@end



@implementation ContentViewController
{
    // MGUISplitViewController private properties
	IBOutlet MGSplitViewController *splitController;
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
    
    float _zoomScale;                       // Current zoom scale of content
}

@synthesize toolbar, popoverController, detailItem, _detailDescriptionLabel;
@synthesize queryData = _queryData;


// Global layout parameters
//float BAND_HEIGHT = -1.0f;  // Height of bands in the interface
//float BAND_WIDTH = -1.0f;   // Width of bands in the interface
BOOL isPortrait = YES;  // Modified on change of device orientation

float BAND_HEIGHT = BAND_HEIGHT_P;
float BAND_WIDTH = BAND_WIDTH_P;
float BAND_SPACING = BAND_SPACING_P;
float TIMELINE_HEIGHT = BAND_HEIGHT_P; // So that labels line up properly and spacing is more distinct

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
    
    // Panel scrubber
    UIView *scrubberBar = [[UIView alloc] init];
    _scrubberBar = scrubberBar;
    //_scrubberBar.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];   // Grey color
    _scrubberBar.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    _scrubberBar.opaque = YES;
    UISlider *pscrub = [[UISlider alloc] init];
    _panelScrubber = pscrub;
    [_panelScrubber addTarget:self action:@selector(scrubberMoved:) forControlEvents:UIControlEventValueChanged];
    [_panelScrubber addTarget:self action:@selector(scrubberStopped:) forControlEvents:UIControlEventTouchUpInside];
    UIImage* trackImage = [UIImage imageNamed:@"scrubber.png"];
    UIImage* useableTrackImage = [trackImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [_panelScrubber setMinimumTrackImage:useableTrackImage forState:UIControlStateNormal];
    [_panelScrubber setMaximumTrackImage:useableTrackImage forState:UIControlStateNormal];
    _panelScrubber.opaque = YES;
    _panelScrubber.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];    // Should be the same as the scrubberBar's background
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
    ContentScrollView *csv = [[ContentScrollView alloc] initWithPanelNum:_queryData.panelNum stackNum:_queryData.stackNum bandNum:_queryData.bandNum];
    _contentScrollView = csv;
    [self.view addSubview:_contentScrollView];
    
    // Establish data delegation
    [_contentScrollView setDataDelegate:self];
    
    // QueryData model
    QueryData *qdata = [[QueryData alloc] init];
    self.queryData = qdata;
    
    _zoomScale = 1.0f;
    
    // Resize interface componenets as necessary
    [self configureView];
}


#pragma mark -
#pragma mark View Sizing

- (void)configureView
{    
    // Panel scrubber
    CGRect scrubberBarFrame;
    CGRect scrubberFrame;
    if (isPortrait)
    {
        scrubberBarFrame = CGRectMake(0.0f, 924.0f, 768.0f, 100.0f);
        scrubberFrame = CGRectMake(100.0f, 0.0f, 568.0f, 50.0f);
    }
    else
    {
        scrubberBarFrame = CGRectMake(0.0, 768.0f, 1024.0f, 100.0f);
        scrubberFrame = CGRectMake(100.0f, 0.0f, 824.0f, 50.0f);
    }
    _scrubberBar.frame = scrubberBarFrame;
    _panelScrubber.frame = scrubberFrame;
    
    // Content scroll view
    CGRect csvFrame;
    if (isPortrait)
    {
        csvFrame = CGRectMake(0.0f, 44.0f, 768.0f, 880.0f);
    }
    else
    {
        csvFrame = CGRectMake(0.0f, 44.0f, 1024.0f, 724.0f);
    }
    _contentScrollView.frame = csvFrame;
    
    [self initScrubber];
    
    [self resizeSubviews];
}

/**
 *  Called whenever a new query is submitted, to resize all of the content-displying subviews to their proper sizes.
 */
- (void)resizeSubviews
{
    [_contentScrollView sizeForPanelNum:_queryData.panelNum stackNum:_queryData.stackNum bandNum:_queryData.bandNum];
}


#pragma mark -
#pragma mark QueryData

/**
 *  Overridden setter for the static query data model, so that necessary updates may be performed when a new query is submitted.
 *  (Legacy, replaced by delegation)Implements the 'copy' property descriptor for thread-safety.
 *
 *  queryData is the new data model object
 */
- (void)setQueryData:(QueryData *)queryData
{
/*
    // Copy protocol
    if (_queryData == queryData)
    {
        return;
    }
//    QueryData *oldValue = _queryData;
    _queryData = [queryData copy];
    ///////
*/
    _queryData = queryData;
    
    [self resizeSubviews];
    
    // Update display with new data
    if (_queryData.panelNum > 0)
        [self changeCurrentPanel:0];
    else
        [self changeCurrentPanel:-1];
    
    for (PanelZoomView *p in _contentScrollView.panelZoomViews)
    {
        [p.panelDrawView setNeedsDisplay];
    }
    
    // Re-initialize scrubber
    [self initScrubber];
}


#pragma mark -
#pragma mark Panel Control

/**
 *  Changes panel and updates the panel scrubber slider and to inform the scroll view and all subviews to redraw the new panel.
 */
- (void)changeCurrentPanel:(int)panelIndex
{
    [_panelScrubber setValue:(float)panelIndex animated:YES];
    [_contentScrollView switchToPanel:panelIndex];
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
    for (UIButton *b in _scrubberButtons)
    {
        [b removeFromSuperview];
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
            frame = CGRectMake(90.0f+(_panelScrubber.frame.size.width/2.0f)-50.0f, 
                                  50.0f, 
                                  100.0f, 
                                  20.0f);
        else
            frame = CGRectMake(90.0f+(_panelScrubber.frame.size.width/(panelNum-1.0f))*i-50.0f, 
                               50.0f, 
                               100.0f, 
                               20.0f);
        
        UIButton *newb = [[UIButton alloc] initWithFrame:frame];
        newb.opaque = YES;
        [newb setBackgroundImage:inactiveImg forState:UIControlStateNormal];
        [newb setBackgroundImage:activeImg forState:UIControlStateHighlighted];
        
        Meta *panelM = [(NSArray *)[_queryData.selectedMetas objectForKey:@"Panels"] objectAtIndex:i];
        [newb setTitle:panelM.name forState:UIControlStateNormal];
        
        newb.tag = i;
        [newb setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [newb addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [butts addObject:newb];
        [_scrubberBar addSubview:newb];
    }
    _scrubberButtons = butts;

//    int roundVal = roundf((float)_panelScrubber.value);
//    
//    if (_queryData.panelNum == 0)
//        roundVal = -1;
//    [_contentScrollView switchToPanel:roundVal];
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
    
    if (((PanelZoomView *)[_contentScrollView.panelZoomViews objectAtIndex:0]).panelDrawView.currentPanel != roundVal)
    {
        [self changeCurrentPanel:roundVal];
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

    for (PanelZoomView *p in _contentScrollView.panelZoomViews)
    {
        [p.panelDrawView setNeedsDisplay];
    }
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
 *  Returns number of bands in current query
 */
- (int)delegateRequestsNumberOfBands
{
    return _queryData.bandNum; 
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

/**
 *  Swap the arrangement of bands in the data model when they are rearranged visually
 */
- (void)swapBand:(int)i withBand:(int)j
{
    // Reorder events
    for (int p = 0; p < _queryData.panelNum; p++)
    {
        for (int s = 0; s < _queryData.stackNum; s++)
        {
            NSMutableArray *mutableBands = [[[_queryData.eventArray objectAtIndex:p] objectAtIndex:s] mutableCopy];
            NSArray *tempBand = [mutableBands objectAtIndex:i];
            [mutableBands replaceObjectAtIndex:i withObject:[mutableBands objectAtIndex:j]];
            [mutableBands replaceObjectAtIndex:j withObject:tempBand];
            [[_queryData.eventArray objectAtIndex:p] replaceObjectAtIndex:s withObject:(NSArray *)mutableBands];
        }
    }
    
    // Reorder meta array
    NSMutableArray *mutableBandMetas = [[_queryData.selectedMetas objectForKey:@"Bands"] mutableCopy];
    Meta *tempMeta = [mutableBandMetas objectAtIndex:i];
    [mutableBandMetas replaceObjectAtIndex:i withObject:[mutableBandMetas objectAtIndex:j]];
    [mutableBandMetas replaceObjectAtIndex:j withObject:tempMeta];
    NSMutableDictionary *mutableMetas = [_queryData.selectedMetas mutableCopy];
    [mutableMetas setObject:(NSArray *)mutableBandMetas forKey:@"Bands"];
    _queryData.selectedMetas = (NSDictionary *)mutableMetas;
}

/**
 *  Swap the arrangement of stacks in the data model when they are rearranged visually
 */
- (void)swapStack:(int)i withStack:(int)j
{
    // Reorder events
    NSMutableArray *mutableEvents = [_queryData.eventArray mutableCopy];
    for (int p = 0; p < _queryData.panelNum; p++)
    {
        NSMutableArray *mutableStacks = [[_queryData.eventArray objectAtIndex:p] mutableCopy];
        NSArray *tempStack = [mutableStacks objectAtIndex:i];
        [mutableStacks replaceObjectAtIndex:i withObject:[mutableStacks objectAtIndex:j]];
        [mutableStacks replaceObjectAtIndex:j withObject:tempStack];
        
        [mutableEvents replaceObjectAtIndex:p withObject:(NSArray *)mutableStacks];
    }
    _queryData.eventArray = (NSArray *)mutableEvents;
    
    // Reorder meta array
    NSMutableArray *mutableStackMetas = [[_queryData.selectedMetas objectForKey:@"Stacks"] mutableCopy];
    Meta *tempMeta = [mutableStackMetas objectAtIndex:i];
    [mutableStackMetas replaceObjectAtIndex:i withObject:[mutableStackMetas objectAtIndex:j]];
    [mutableStackMetas replaceObjectAtIndex:j withObject:tempMeta];
    NSMutableDictionary *mutableMetas = [_queryData.selectedMetas mutableCopy];
    [mutableMetas setObject:(NSArray *)mutableStackMetas forKey:@"Stacks"];
    _queryData.selectedMetas = (NSDictionary *)mutableMetas;
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
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        isPortrait = YES;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        isPortrait = NO;
    }
    
    [self configureView];
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
