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
    NSArray *_panelViews;           // Static array of all PanelViews
    
    UILabel *_draggingLabel;        // Label currently being dragged
    CALayer *_draggingStackLayer;   // Stack layer currently being dragged
    BandLayer *_draggingBandLayer;  // Band layer currently being dragged
    int _draggingBandIndex;         // Original index of the band currently being dragged
    int _draggingStackIndex;        // Original index of the stack or the stack of the current band being dragged
    NSArray *_stackLabelArray;      // Array of labels for each stack
    NSArray *_bandLabelArray;       // 2-dimensional array of labels for each band (indexed by stack then by band)
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
        dragGesture.delegate = self;
        [dragGesture setNumberOfTouchesRequired:1];
        [self addGestureRecognizer:dragGesture];
    }
    
    return self;
}

/**
 *  Resize this view to fit the specified number of stacks and bands.
 *  Should also inform all subviews to do the same.
 *
 *  stackNum is the number of stacks in the new query
 *  bandNum is the number of bands in the new query
 */
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    [_bandZoomView resizeForStackNum:stackNum bandNum:bandNum];
    if (self.contentSize.height != _bandZoomView.frame.size.height || self.contentSize.width != _bandZoomView.frame.size.width)
    {
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


#pragma mark -
#pragma mark Label management

/**
 *  Create and displays all labels for the individual bands and stacks
 */
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
        [self insertSubview:stackL belowSubview:_bandZoomView];
        [newStackLabels addObject:stackL];
		
        NSMutableArray *currentBandLabels = [[NSMutableArray alloc] init];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT_P);
			UILabel *bandL = [[UILabel alloc] initWithFrame:labelF];
			[bandL setTextAlignment:UITextAlignmentRight];
            [bandL setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
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

/**
 *  Swap all band labels EXCEPT for the currently dragged label
 *  
 *  draggingIndex is the index of the label currently being dragged
 *  otherIndex is the index of the label being swapped
 */
- (void)swapAllBandLabels:(int)draggingIndex and:(int)otherIndex
{
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    int stack = 0;
    NSMutableArray *bandLabelsMutable = [_bandLabelArray mutableCopy];
    for (int i = 0; i < [bandLabelsMutable count]; i++)
    {
        float stackY = stack * stackHeight;
        NSMutableArray *arrMutable = [bandLabelsMutable objectAtIndex:i];
        
        // Move all labels corresponding to the label currently being dragged
        UILabel *draggingLabel = [arrMutable objectAtIndex:draggingIndex];
        if (_draggingStackIndex != stack)
        {
            float draggingY = otherIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect draggingF = draggingLabel.frame;
            draggingF.origin.y = draggingY;
            draggingLabel.frame = draggingF;
        }
        
        // Move labels correspondind to the label not being dragged that is being swapped
        UILabel *otherLabel = [arrMutable objectAtIndex:otherIndex];
        float otherY = draggingIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
        CGRect otherF = otherLabel.frame;
        otherF.origin.y = otherY;
        otherLabel.frame = otherF;
        
        // Reorder label in array
        [arrMutable replaceObjectAtIndex:draggingIndex withObject:otherLabel];
        [arrMutable replaceObjectAtIndex:otherIndex withObject:draggingLabel];
        
        [bandLabelsMutable replaceObjectAtIndex:i withObject:(NSArray *)arrMutable];
        stack++;
    }
    
    _bandLabelArray = (NSArray *)bandLabelsMutable;
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
    
    // Find label and related layer
    for (int i = 0; i < [_stackLabelArray count]; i++)
    {
        UILabel *s = [_stackLabelArray objectAtIndex:i];
        if (CGRectContainsPoint(s.frame, point))
        {
            _draggingLabel = s;
            [_draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:24.0f]];
            _draggingStackLayer = [_drawDelegate getStackLayerForStack:i];
            _draggingStackIndex = i;
            break;
        }
    }
    // If the label isn't a stack label, check band labels
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
                    [_draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:20.0f]];
                    _draggingBandLayer = [_drawDelegate getBandLayerForStack:i band:j];
                    _draggingBandIndex = j;
                    _draggingStackIndex = i;
                    found = YES;
                    break;
                }
            }
            if (found) break;
        }
    }
    
    _draggingLabel.opaque = NO;
    _draggingLabel.backgroundColor = [UIColor clearColor];
    [self insertSubview:_draggingLabel aboveSubview:_bandZoomView];
}

/**
 *  Move the temporary draggingCell to the new location specified by the gesture recognizer's new point.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer
{    
    if (_draggingLabel)
    {
        CGPoint point = [gestureRecognizer locationInView:self];
        point.x = _draggingLabel.center.x;
        
        float yDiff = point.y - _draggingLabel.center.y;
        
        [_draggingLabel setCenter:point];
        
        if (_draggingBandLayer)
        {
            CGPoint pos = CGPointMake(_draggingBandLayer.position.x, 
                                      _draggingBandLayer.position.y + yDiff);
            // Check to reorder
            int newIndex = pos.y / (BAND_HEIGHT_P + BAND_SPACING);
            if (newIndex != _draggingBandIndex && newIndex >= 0)
            {                
                if ([_drawDelegate reorderBandsAroundBand:_draggingBandIndex inStack:_draggingStackIndex withNewIndex:newIndex])
                {
                   [self swapAllBandLabels:_draggingBandIndex and:newIndex];
                    
                    _draggingBandIndex = newIndex;
                }
            }
            
            [_draggingBandLayer setPosition:pos];
        }
        else if (_draggingStackLayer)
        {
            CGPoint pos = CGPointMake(_draggingStackLayer.position.x, 
                                      _draggingStackLayer.position.y + yDiff);
            [_draggingStackLayer setPosition:pos];
        }
        else
            NSLog(@"ERROR! -- No layer associated with label %@ %@", _draggingBandLayer, _draggingStackLayer);
    }
}

/**
 *  Handle the resulting location of the dragged table cell, depending on where hit-tests register.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{
    _draggingLabel.opaque = YES;
    _draggingLabel.backgroundColor = [UIColor whiteColor];
    [self insertSubview:_draggingLabel belowSubview:_bandZoomView];
    
    // Set new position for dropped layer based on its index
    if (_draggingBandLayer)
    {
        [_drawDelegate moveBandToRestWithIndex:_draggingBandIndex inStack:_draggingStackIndex];
        // Move label to rest
        QueryData *data = [_dataDelegate delegateRequestsQueryData];
        float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
        float stackY = _draggingStackIndex * stackHeight;
        float bandY = _draggingBandIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
        CGRect labelF = _draggingLabel.frame;
        labelF.origin.y = bandY;
        _draggingLabel.frame = labelF;
        [_draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
    }
    else if (_draggingStackLayer)
    {
        
    }
    else
        NSLog(@"ERROR! -- No layer associated with label %@ %@", _draggingBandLayer, _draggingStackLayer);
    
    _draggingLabel = nil;
    _draggingStackLayer = nil;
    _draggingBandLayer = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{        
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        [gestureRecognizer view] == [otherGestureRecognizer view])
    {
        if (gestureRecognizer == otherGestureRecognizer) NSLog(@"Gesture recognizers are equal");
        return YES;
    }
    else
    {
        return NO;
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
