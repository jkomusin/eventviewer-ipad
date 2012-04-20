
#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "PanelDrawView.h"
#import "ContentScrollView.h"

// Constants containing dimensions of bands in each device orientation.
//  All other measurements of UI elements are based off of these dimensions.
#define BAND_HEIGHT_P 64.0f
#define BAND_WIDTH_P 529.0f
#define BAND_SPACING_P 8.0f
#define TIMELINE_HEIGHT_P 64.0f


@class SecondaryViewController;
@class QueryViewController;
@class QueryBuilderView;
@class Query;
@class Constraint;

/**
 *  Enumeration for the three primary interface objects: bands, stacks, and panels
 */
enum UI_OBJECT
{
    UIObjectBand = 0,
    UIObjectStack = 1,
    UIObjectPanel = 2
};

/**
 *	Enumeration for overlay styles
 */
enum EVENT_STYLE
{
	UIEventStylePlain = 0,	// Basic overlay, nothing special, uses panel's color for Events
	UIEventStyleOverlap = 1,	// Event color based on number of Events overlapping
	UIEventStyleMagnitude = 2	// Event color based on magnitude of Events
};


/**
 *  Delegate protocol to provide access to the data model to outside objects.
 */
@protocol DataDelegate
@required
- (Query *)delegateRequestsQueryData;
- (NSInteger)delegateRequestsNumberOfBands;
- (NSArray *)delegateRequestsOverlays;
- (NSInteger)delegateRequestsTimescale;
- (void)swapBandData:(NSInteger)i withBand:(NSInteger)j;
- (void)swapStackData:(NSInteger)i withStack:(NSInteger)j;
- (void)swapPanelData:(NSInteger)i withPanel:(NSInteger)j;
- (UIColor *)getColorForPanel:(NSInteger)panelIndex;

@end

/**
 *  Delegate protocol to provide notifications of login status.
 */
@protocol LoginDelegate
@required
- (void)loginToDatabaseSucceeded;
- (void)loginToDatabaseFailedWithError:(NSString *)error;

@end

/**
 *  Delegate protocol to provide notifications of query updates.
 */
@protocol ContentDelegate
@required
- (void)queryHasRecievedData;
- (void)swapBandLayer:(NSInteger)i withBand:(NSInteger)j;
- (void)swapStackLayer:(NSInteger)i withStack:(NSInteger)j;
- (void)swapPanelLayer:(NSInteger)i withPanel:(NSInteger)j;
- (void)reConfigureCanvas;

@end


/**
 *  "Primary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the results of a query, as well as the query-building interface.
 */
@interface PrimaryViewController : UIViewController 
    <UIPopoverControllerDelegate, UIGestureRecognizerDelegate, MGSplitViewControllerDelegate, DataDelegate, LoginDelegate, ContentDelegate> 

// MGUISplitViewController public properties
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) id detailItem;
@property (nonatomic, strong) IBOutlet UILabel *_detailDescriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *_detailTitleLabel;
// MGUISplitViewController methods
- (IBAction)toggleMasterView:(id)sender;
- (IBAction)toggleVertical:(id)sender;
- (IBAction)toggleDividerStyle:(id)sender;
- (IBAction)toggleMasterBeforeDetail:(id)sender;
///////

@property (nonatomic, strong) SecondaryViewController *masterViewController;    // Other controller in split view

@property (nonatomic, strong) QueryBuilderView *queryView;  // View for building and submitting a query
@property (nonatomic, strong) Query *queryData;   // Model object containing and managing all data forming the current query and its results

- (void)loginToDefault;

- (void)handleInterfaceRotationForOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)configureView;

- (BOOL)droppedViewWithGestureRecognizer:(UIGestureRecognizer *)recognizer forConstraint:(Constraint *)constraint;

- (void)showQueryBuilder;
- (void)hideQueryBuilderAndRemove:(BOOL)remove;

- (void)initScrubber;
- (void)scrubberMoved:(id)sender;
- (void)scrubberStopped:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)eventButtonPressed;
- (void)changeCurrentPanel:(NSInteger)panelIndex;

- (void)swapBandLayer:(NSInteger)i withBand:(NSInteger)j;
- (void)swapStackLayer:(NSInteger)i withStack:(NSInteger)j;
- (void)swapPanelLayer:(NSInteger)i withPanel:(NSInteger)j;

- (void)resizeSubviews;

@end
