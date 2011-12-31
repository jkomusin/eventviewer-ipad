
#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "PanelDrawView.h"
#import "ContentScrollView.h"

@class QueryViewController;
@class QueryData;
@class ContentScrollView;

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
- (QueryData *)delegateRequestsQueryData;
- (int)delegateRequestsNumberOfBands;
- (NSArray *)delegateRequestsOverlays;
- (int)delegateRequestsTimescale;
- (void)swapBand:(int)i withBand:(int)j;

@end


/**
 *  "Primary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the results of a query.
 */
@interface ContentViewController : UIViewController <UIPopoverControllerDelegate, MGSplitViewControllerDelegate, DataDelegate> 

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

@property (nonatomic, copy) QueryData *queryData;   // Model object containing and managing all data forming the current query and its results

- (void)handleInterfaceRotationForOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)pointIsInsideScrubber:(UIPanGestureRecognizer *)recognizer;
- (void)changeCurrentPanel:(int)panelIndex;
- (void)initScrubber;
- (void)buttonPressed:(id)sender;
- (void)addNewPanel;
- (void)resizeSubviews;

@end
