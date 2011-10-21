//
//  DetailViewController.h
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "QueryData.h"

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
    UIScrollView *_contentScrollView;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) id detailItem;
@property (nonatomic, retain) IBOutlet UILabel *_detailDescriptionLabel;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) QueryData *queryData;

- (void)configureView;
- (IBAction)toggleMasterView:(id)sender;
- (IBAction)toggleVertical:(id)sender;
- (IBAction)toggleDividerStyle:(id)sender;
- (IBAction)toggleMasterBeforeDetail:(id)sender;

@end
