//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentScrollView.h"
#import "BandZoomView.h"
#import "BandDrawView.h"
#import "QueryData.h"

@implementation ContentScrollView
{
	id<DataDelegate> dataDelegate;
    NSArray *_panelViews;   // Static array of all PanelViews
}

@synthesize dataDelegate = _dataDelegate;
@synthesize currentPanel = _currentPanel;
@synthesize bandZoomView = _bandZoomView;


#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        NSArray *newArr = [[NSArray alloc] init];
        _panelViews = newArr;
        _currentPanel = -1;
        BandZoomView *zoomView = [[BandZoomView alloc] initWithStackNum:0 bandNum:0];
        [self addSubview:zoomView];
        _bandZoomView = zoomView;
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		[self setBackgroundColor:[UIColor whiteColor]];
		
		[self createLabels];
    }
    
    return self;
}

- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    [_bandZoomView resizeForStackNum:stackNum bandNum:bandNum];
    if (self.contentSize.height != _bandZoomView.frame.size.height || self.contentSize.width != _bandZoomView.frame.size.width)
    {
        NSLog(@"Resizing CSV");
        self.contentSize = _bandZoomView.frame.size;
    }
	
	[self createLabels];
}

/**
 *  Display a specific panel in the array of panels, hiding the previously displayed panel.
 *  (assuming the previous panel is not statically visable)
 *
 *  panelNum is the array index of the panel to switch the view to (0-indexed)
 */
- (void)switchToPanel:(int)panelNum
{
    if (panelNum == _currentPanel)
        return;

    _currentPanel = panelNum;
    [_bandZoomView.bandDrawView setNeedsDisplay];
}

- (void)createLabels
{
	QueryData *data = [_dataDelegate delegateRequestsQueryData];
	
	// Remove old labels
	for (UIView *sub in self.subviews)
	{
		if ([sub isKindOfClass:[UILabel class]])
			[sub removeFromSuperview];
	}
	
	// Create new labels
	float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
		CGRect labelF = CGRectMake(16.0f, stackY, 128.0f, 32.0f);
		UILabel *stackL = [[UILabel alloc] initWithFrame:labelF];
		[stackL setTextAlignment:UITextAlignmentLeft];
		[stackL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
		NSString *stackM = [(NSArray *)[data.selectedMetas objectForKey:@"Stacks"] objectAtIndex:i];
		[stackL setText:stackM];
		[self addSubview:stackL];
		
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT_P);
			UILabel *metaL = [[UILabel alloc] initWithFrame:labelF];
			[metaL setTextAlignment:UITextAlignmentRight];
			NSString *meta = [(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j];
			[metaL setText:meta];
			[self addSubview:metaL];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	NSLog(@"ContentView DRAW RECT!!!");
	
	CGContextRef context = UIGraphicsGetCurrentContext();
    QueryData *data = [dataDelegate contentViewRequestQueryData];
	
	// Draw labels
	float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT_P);
			NSString *meta = [(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j];
			[meta drawInRect:labelF withFont:[UIFont fontWithName:@"Helvetica" size:20.0f] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
        }
    }
}
*/

@end
