
#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "QueryViewController.h"
#import "QueryData.h"
#import "ContentScrollView.h"

#define TEST_STACKS 4
#define TEST_BANDS 5

@interface ContentViewController : UIViewController <UIPopoverControllerDelegate, MGSplitViewControllerDelegate> {
	IBOutlet MGSplitViewController *splitController;
	IBOutlet UIBarButtonItem *toggleItem;
	IBOutlet UIBarButtonItem *verticalItem;
	IBOutlet UIBarButtonItem *dividerStyleItem;
	IBOutlet UIBarButtonItem *masterBeforeDetailItem;
    UIPopoverController *popoverController;
    UIToolbar *toolbar;
    
    id detailItem;
    UILabel *_detailDescriptionLabel;
    
    UISlider *_panelScrubber;
    UIView *_scrubberBar;
    NSArray *_scrubberButtons;
    ContentScrollView *_contentScrollView;
}

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) id detailItem;
@property (nonatomic, strong) IBOutlet UILabel *_detailDescriptionLabel;
@property (nonatomic, copy) QueryData *queryData;

- (IBAction)toggleMasterView:(id)sender;
- (IBAction)toggleVertical:(id)sender;
- (IBAction)toggleDividerStyle:(id)sender;
- (IBAction)toggleMasterBeforeDetail:(id)sender;

@end
