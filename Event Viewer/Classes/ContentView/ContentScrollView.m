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
#import "BandLayer.h"
#import "QueryData.h"

@implementation ContentScrollView
{
	id<DataDelegate> dataDelegate;
    id<DrawDelegate> drawDelegate;
    NSArray *_panelViews;   // Static array of all PanelViews
    
    UILabel *_draggingLabel;        // Label currently being dragged
    CALayer *_draggingStackLayer;   // Stack layer currently being dragged
    BandLayer *_draggingBandLayer;  // Band layer currently being dragged
    NSArray *_stackLabelArray;      // Array of labels for each stack
    NSArray *_bandLabelArray;       // 2-dimensional array of labels for each band (indexed by stack then by band)
    
    float _draggingY;               // Previous y-coordinate of dragging gesture
}

@synthesize dataDelegate = _dataDelegate;
@synthesize drawDelegate = _drawDelegate;
@synthesize currentPanel = _currentPanel;
@synthesize bandZoomView = _bandZoomView;


#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        [self createLabels];
        
        NSArray *newArr = [[NSArray alloc] init];
        _panelViews = newArr;
        _currentPanel = -1;
        BandZoomView *zoomView = [[BandZoomView alloc] initWithStackNum:0 bandNum:0];
        [self addSubview:zoomView];
        _bandZoomView = zoomView;
        _drawDelegate = zoomView.bandDrawView;
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		[self setBackgroundColor:[UIColor whiteColor]];
        
        UILongPressGestureRecognizer* dragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        [dragGesture setNumberOfTouchesRequired:1];
        [self addGestureRecognizer:dragGesture];
        
        _draggingY = 0.0f;
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
    NSMutableArray *newStackLabels = [[NSMutableArray alloc] init];
    NSMutableArray *newBandLabels = [[NSMutableArray alloc] init];
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
        [newStackLabels addObject:stackL];
		
        NSMutableArray *currentBandLabels = [[NSMutableArray alloc] init];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT_P);
			UILabel *bandL = [[UILabel alloc] initWithFrame:labelF];
			[bandL setTextAlignment:UITextAlignmentRight];
			NSString *meta = [(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j];
			[bandL setText:meta];
			[self addSubview:bandL];
            [self insertSubview:bandL belowSubview:_bandZoomView];
            [currentBandLabels addObject:bandL];
        }
        [newBandLabels addObject:(NSArray *)currentBandLabels];
    }
    
    _stackLabelArray = (NSArray *)newStackLabels;
    _bandLabelArray = (NSArray *)newBandLabels;
}


#pragma mark -
#pragma mark Drag-and-drop Handling

/**
 *  Initial entry point for a drag-and-drop gesture.
 *  Deals with all actions occurring inside the LongPressGestureRecognizer.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)handleDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch ([gestureRecognizer state]) 
    {
        case UIGestureRecognizerStateBegan:
            [self startDragging:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self doDrag:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self stopDragging:gestureRecognizer];
            break;
        default:
            break;
    }
}

/**
 *  Initialize the label and layer for dragging
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    _draggingY = point.y;
    
    // Find label and related layer
    for (int i = 0; i < [_stackLabelArray count]; i++)
    {
        UILabel *s = [_stackLabelArray objectAtIndex:i];
        if (CGRectContainsPoint(s.frame, point))
        {
            _draggingLabel = s;
            [self insertSubview:s aboveSubview:_bandZoomView];
            _draggingStackLayer = [drawDelegate getStackLayerForStack:i];
            break;
        }
    }
    if (!_draggingLabel)
    {
        for (int i = 0; i < [_bandLabelArray count]; i++)
        {   
            BOOL found = NO;
            NSArray *bandArray = [_bandLabelArray objectAtIndex:i];
            for (int j = 0; j < [bandArray count]; j++)
            {
                UILabel *b = [bandArray objectAtIndex:j];
                if (CGRectContainsPoint(b.frame, point))
                {
                    _draggingLabel = b;
                    _draggingBandLayer = [drawDelegate getBandLayerForStack:i band:j];
                    found = YES;
                    break;
                }
            }
            if (found) break;
        }
    }
}

/**
 *  Initialize the temporary cell to be visually dragged across the screen.
 *
 *  cell is the table cell in the table view that has begun to be dragged.
 *  origin is the point representing the absolute origin of the point in the MGUISplitViewController.
 */
- (void)initDraggingCellWithCell:(UITableViewCell*)cell AtOrigin:(CGPoint)origin
{
//    if(draggingCell != nil)
//    {
//        [draggingCell removeFromSuperview];
//        draggingCell = nil;
//    }
//    
//    CGRect frame = CGRectMake(origin.x, origin.y, cell.frame.size.width, cell.frame.size.height);
//    
//    draggingCell = [[UITableViewCell alloc] init];
//    draggingCell.selectionStyle = UITableViewCellSelectionStyleBlue;
//    draggingCell.textLabel.text = cell.textLabel.text;
//    draggingCell.textLabel.textColor = cell.textLabel.textColor;
//    draggingCell.highlighted = YES;
//    draggingCell.frame = frame;
//    draggingCell.alpha = 0.8;
//    
//    [_detailViewController.view addSubview:draggingCell];
}

/**
 *  Move the temporary draggingCell to the new location specified by the gesture recognizer's new point.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (_draggingLabel)
    {
        CGPoint point = [gestureRecognizer locationInView:self];
        [_draggingLabel setCenter:point];
        
        float yDiff = point.y - _draggingY;
        _draggingY = point.y;
        
        if (_draggingBandLayer)
        {
            CGPoint pos = CGPointMake(_draggingBandLayer.position.x, 
                                      _draggingBandLayer.position.y + yDiff);
            [_draggingBandLayer setPosition:pos];
        }
        else if (_draggingStackLayer)
        {
            CGPoint pos = CGPointMake(_draggingStackLayer.position.x, 
                                      _draggingStackLayer.position.y + yDiff);
            [_draggingStackLayer setPosition:pos];
        }
        else
            NSLog(@"ERROR! -- No layer associated with label");
    }
}

/**
 *  Handle the resulting location of the dragged table cell, depending on where hit-tests register.
 *
 *  gestureRecognizer is the UIPanGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UIPanGestureRecognizer *)gestureRecognizer
{
    _draggingLabel = nil;
    _draggingStackLayer = nil;
    _draggingBandLayer = nil;
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
