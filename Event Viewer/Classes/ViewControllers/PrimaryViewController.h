
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
    BAND = 0,
    STACK = 1,
    PANEL = 2
};


/**
 *  Delegate protocol to provide access to the data model to outside objects.
 */
@protocol DataDelegate
@required
- (Query *)delegateRequestsQueryData;
- (int)delegateRequestsNumberOfBands;
- (NSArray *)delegateRequestsOverlays;
- (int)delegateRequestsTimescale;
- (void)swapBand:(int)i withBand:(int)j;
- (void)swapStack:(int)i withStack:(int)j;
- (void)swapPanel:(int)i withPanel:(int)j;
- (UIColor *)getColorForPanel:(int)panelIndex;

@end

/**
 *  Delegate protocol to provide notifications of login status.
 */
@protocol LoginDelegate
@required
- (void)loginToDatabaseSucceeded;
- (void)loginToDatabaseFailed;

@end


/**
 *  "Primary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the results of a query, as well as the query-building interface.
 */
@interface PrimaryViewController : UIViewController 
    <UIPopoverControllerDelegate, UIGestureRecognizerDelegate, MGSplitViewControllerDelegate, DataDelegate, LoginDelegate> 

// MGUISplitViewController public properties
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) id detailItem;
@property (nonatomic, strong) IBOutlet UILabel *_detailDescriptionLabel;
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

- (void)droppedViewWithGestureRecognizer:(UIGestureRecognizer *)recognizer forConstraint:(Constraint *)constraint;

- (void)showQueryBuilder;
- (void)hideQueryBuilderAndRemove:(BOOL)remove;

- (void)initScrubber;
- (void)scrubberMoved:(id)sender;
- (void)scrubberStopped:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)changeCurrentPanel:(int)panelIndex;

- (void)handleDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)swapButton:(int)i toIndex:(int)j;

- (void)resizeSubviews;

@end
