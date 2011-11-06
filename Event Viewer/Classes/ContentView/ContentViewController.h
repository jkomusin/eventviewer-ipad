
#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "BandDrawView.h"

@class QueryViewController;
@class QueryData;
@class ContentScrollView;

/**
 *  "Primary" ViewController displayed in the MGUISplitViewController
 *
 *  Used in Event Viewer to display the results of a query.
 */
@interface ContentViewController : UIViewController <UIPopoverControllerDelegate, MGSplitViewControllerDelegate, BandDrawViewDelegate> 
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
    ContentScrollView *_contentScrollView;  // Scrolling container for the results of the query
}

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
- (void)initScrubber;
- (void)buttonPressed:(id)sender;
- (void)addNewPanel;

@end
