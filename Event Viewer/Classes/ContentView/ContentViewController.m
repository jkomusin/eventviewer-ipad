
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
    scrubberBar.backgroundColor = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
    scrubberBar.opaque = YES;
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
    _panelScrubber.maximumValue = (float)_queryData.panelNum;
    _panelScrubber.minimumValue = 0.0;
    _panelScrubber.value = 0.0;
    [scrubberBar addSubview:_panelScrubber];
    [self.view addSubview:scrubberBar];
    
    //create scroll view for content
    CGRect csvFrame = CGRectMake(0.0, 44.0, 768.0, 880.0);
    ContentScrollView *csv = [[ContentScrollView alloc] initWithFrame:csvFrame];
    _contentScrollView = csv;
    [self.view addSubview:_contentScrollView];
}


#pragma mark -
#pragma mark QueryData

- (void)setQueryData:(QueryData *)queryData
{
    if (_queryData == queryData)
    {
        return;
    }
    QueryData *oldValue = _queryData;
    _queryData = [queryData copy];
    
    //update display with new data
    if (_queryData.panelNum > oldValue.panelNum)
    {
        //add new panels
        for (int i = 0; i < _queryData.panelNum - oldValue.panelNum; i++)
        {
            [_contentScrollView addPanelWithStacks:6 Bands:5];
        }
    }
    else if (_queryData.panelNum < oldValue.panelNum)
    {
        //remove excess panels
        for (int i = 0; i < oldValue.panelNum - _queryData.panelNum; i++)
        {
            [_contentScrollView removePanel];
        }
    }
    
    //updated scrubber
    _panelScrubber.maximumValue = (_queryData.panelNum > 0 ? (float)_queryData.panelNum - 1 : 0);
    if (_panelScrubber.value > _panelScrubber.maximumValue)
        _panelScrubber.value = _panelScrubber.maximumValue;
    //show appropriate view
    int roundVal = roundf((float)_panelScrubber.value);
    [_contentScrollView switchToPanel:roundVal];
    NSLog(@"Switching to panel %d", roundVal);
    
}


#pragma mark -
#pragma mark Panel Scrubber Control

- (void)scrubberMoved:(id)sender
{
    //show appropriate view
    int roundVal = roundf((float)_panelScrubber.value);
    [_contentScrollView switchToPanel:roundVal];
    NSLog(@"Switching to panel %d", roundVal);
}

- (void)scrubberStopped:(id)sender
{
    int roundVal = roundf((float)_panelScrubber.value);
    [_panelScrubber setValue:(float)roundVal animated:YES];
    //show appropriate view
    [_contentScrollView switchToPanel:roundVal];
    NSLog(@"Switching to panel %d", roundVal);
}


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
