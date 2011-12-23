
#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "BandDrawView.h"
#import "ContentScrollView.h"

@class QueryViewController;
@class QueryData;
@class ContentScrollView;

/**
 *  Delegate protocol to provide access to the data model to outside objects.
 */
@protocol DataDelegate
@required
- (QueryData *)delegateRequestsQueryData;
- (int)delegateRequestsCurrentPanel;
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
@property (nonatomic, assign) int currentPanel;     // Currently selected panel

- (void)handleInterfaceRotationForOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)pointIsInsideScrubber:(UIPanGestureRecognizer *)recognizer;
- (void)initScrubber;
- (void)buttonPressed:(id)sender;
- (void)addNewPanel;
- (void)resizeSubviews;

@end
