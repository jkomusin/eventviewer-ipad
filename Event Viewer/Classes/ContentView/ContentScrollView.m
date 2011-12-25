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

@interface ContentScrollView ()
- (void)createLabels;
- (void)swapAllBandLabels:(int)draggingIndex and:(int)otherIndex skippingStack:(int)skipStackIndex areBothDragging:(BOOL)bothDragging;
- (void)swapStackLabels:(int)draggingIndex and:(int)otherIndex;
@end

@implementation ContentScrollView
{
	id<DataDelegate> dataDelegate;
    id<DrawDelegate> drawDelegate;
    
    NSArray *_draggingLabels;       // 2-dimensional array of labels and their associated information as such:
                                    //  Index of outer array corresponds to each dragging label
                                    //  [x][0] corresponds to the UILabel being dragged
                                    //  [x][1] corresponds to the layer being dragged (may be a Stack of Band, should check by using properties of BandLayers
                                    //  [x][2] corresponds to the index of the stack being dragged or dragged inside
                                    //  [x][3] corresponds to the index of the band being dragged (obviously optional if a stack is being dragged)
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
        
        NSArray *newDraggingArr = [[NSArray alloc] init];
        _draggingLabels = newDraggingArr;
        _currentPanel = -1;
        BandZoomView *zoomView = [[BandZoomView alloc] initWithStackNum:0 bandNum:0];
        [self addSubview:zoomView];
        _bandZoomView = zoomView;
        _drawDelegate = zoomView.bandDrawView;
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		[self setBackgroundColor:[UIColor blackColor]];
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
    _bandZoomView.bandDrawView.layer.contents = nil;
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
        [stackL setOpaque:YES];
        [stackL setBackgroundColor:[UIColor blackColor]];
        [stackL setTextColor:[UIColor whiteColor]];
		NSString *stackM = [(NSArray *)[data.selectedMetas objectForKey:@"Stacks"] objectAtIndex:i];
		[stackL setText:stackM];
        
        UILongPressGestureRecognizer* sDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        sDragGesture.delegate = self;
        [sDragGesture setNumberOfTouchesRequired:1];
        [stackL addGestureRecognizer:sDragGesture];
        [stackL setUserInteractionEnabled:YES];
        
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
            [bandL setOpaque:YES];
            [bandL setBackgroundColor:[UIColor blackColor]];
            [bandL setTextColor:[UIColor whiteColor]];
			NSString *meta = [(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j];
			[bandL setText:meta];
            
            UILongPressGestureRecognizer* bDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
            bDragGesture.delegate = self;
            [bDragGesture setNumberOfTouchesRequired:1];
            [bandL addGestureRecognizer:bDragGesture];
            [bandL setUserInteractionEnabled:YES];
            
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
 *  Swap stack labels within the label array
 *
 *  draggingIndex is the index of the label currently being dragged
 *  otherIndex is the index of the label being swapped
 */
- (void)swapStackLabels:(int)draggingIndex and:(int)otherIndex
{
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    
    UILabel *draggingLabel = [_stackLabelArray objectAtIndex:draggingIndex];
    UILabel *otherLabel = [_stackLabelArray objectAtIndex:otherIndex];
    
    float stackY = draggingIndex * stackHeight;
    CGRect labelF = otherLabel.frame;
    labelF.origin.y = stackY;
    otherLabel.frame = labelF;
    
    // Reorder label in array
    NSMutableArray *mutaStackLabels = [_stackLabelArray mutableCopy];
    [mutaStackLabels replaceObjectAtIndex:draggingIndex withObject:otherLabel];
    [mutaStackLabels replaceObjectAtIndex:otherIndex withObject:draggingLabel];
    
    _stackLabelArray = (NSArray *)mutaStackLabels;
}

/**
 *  Swap all band labels EXCEPT for the currently dragged label in current stack
 *  OR in the case they are both being dragged, swap all labels in stacks other than the current one
 *  
 *  draggingIndex is the index of the label currently being dragged
 *  otherIndex is the index of the label being swapped
 */
- (void)swapAllBandLabels:(int)draggingIndex and:(int)otherIndex skippingStack:(int)skipStackIndex areBothDragging:(BOOL)bothDragging
{
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    NSMutableArray *bandLabelsMutable = [_bandLabelArray mutableCopy];
    for (int i = 0; i < [bandLabelsMutable count]; i++)
    {
        float stackY = i * stackHeight;
        NSMutableArray *arrMutable = [bandLabelsMutable objectAtIndex:i];
        
        // Move all labels corresponding to the label currently being dragged
        UILabel *draggingLabel = [arrMutable objectAtIndex:draggingIndex];
        if (i != skipStackIndex)
        {
            float draggingY = otherIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect draggingF = draggingLabel.frame;
            draggingF.origin.y = draggingY;
            draggingLabel.frame = draggingF;
        }
        
        // Move labels corresponding to the label not being dragged that is being swapped
        UILabel *otherLabel = [arrMutable objectAtIndex:otherIndex];
        if (!bothDragging || i != skipStackIndex)
        {
            float otherY = draggingIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect otherF = otherLabel.frame;
            otherF.origin.y = otherY;
            otherLabel.frame = otherF;
        }
            
        // Reorder label in array
        [arrMutable replaceObjectAtIndex:draggingIndex withObject:otherLabel];
        [arrMutable replaceObjectAtIndex:otherIndex withObject:draggingLabel];
        
        [bandLabelsMutable replaceObjectAtIndex:i withObject:(NSArray *)arrMutable];
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
    BOOL isStack = NO;
    for (int i = 0; i < [_stackLabelArray count]; i++)
    {
        UILabel *s = [_stackLabelArray objectAtIndex:i];
        if (CGRectContainsPoint(s.frame, point))
        {
            NSMutableArray *draggingStack = [[NSMutableArray alloc] init];
            [draggingStack addObject:s];
            [draggingStack addObject:[_drawDelegate getStackLayerForStack:i]];
            [draggingStack addObject:[NSNumber numberWithInt:i]];
            [draggingStack addObject:[NSNumber numberWithInt:-1]];
            [s setFont:[UIFont fontWithName:@"Helvetica-Bold" size:24.0f]];
            [s setOpaque:NO];
            [s setBackgroundColor:[UIColor clearColor]];
            [self insertSubview:s aboveSubview:_bandZoomView];
            
            // Insert into dragging array ordered based on y-coord of all dragging labels
            NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
            int l;
            for (l = 0; l < [mutaDraggingLabels count]; l++)
            {
                UILabel *currentL = [[mutaDraggingLabels objectAtIndex:l] objectAtIndex:0];
                
                if (currentL.frame.origin.y > s.frame.origin.y) break;
            }
            [mutaDraggingLabels insertObject:draggingStack atIndex:l];
            
            _draggingLabels = (NSArray *)mutaDraggingLabels;
            
            isStack = YES;
            break;
        }
    }
    // If the label isn't a stack label, check band labels
    if (!isStack)
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
                    NSMutableArray *draggingBand = [[NSMutableArray alloc] init];
                    [draggingBand addObject:b];
                    [draggingBand addObject:[_drawDelegate getBandLayerForStack:i band:j]];
                    [draggingBand addObject:[NSNumber numberWithInt:i]];
                    [draggingBand addObject:[NSNumber numberWithInt:j]];
                    [b setFont:[UIFont fontWithName:@"Helvetica" size:20.0f]];
                    [b setOpaque:NO];
                    [b setBackgroundColor:[UIColor clearColor]];
                    [self insertSubview:b aboveSubview:_bandZoomView];
                    
                    // Insert into dragging array ordered based on y-coord of all dragging labels
                    NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                    int l;
                    for (l = 0; l < [mutaDraggingLabels count]; l++)
                    {
                        UILabel *currentL = [[mutaDraggingLabels objectAtIndex:l] objectAtIndex:0];
                        
                        if (currentL.frame.origin.y > b.frame.origin.y) break;
                    }
                    [mutaDraggingLabels insertObject:draggingBand atIndex:l];
                    
                    _draggingLabels = (NSArray *)mutaDraggingLabels;
                    
                    found = YES;
                    break;
                }
            }
            if (found) break;
        }
    }
}

/**
 *  Handle the moving of the UILabel corresponding to a band or stack.
 *  Check if re-ordering is necessary and if so, re-order.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer
{    
    UILabel *draggingLabel = (UILabel *)[gestureRecognizer view];
    NSArray *draggingArr;
    int draggingLabelIndex = -1;
    for (int i = 0; i < [_draggingLabels count]; i++)
    {
        NSArray *a = [_draggingLabels objectAtIndex:i];
        if ([a objectAtIndex:0] == draggingLabel)
        {
            draggingArr = a;
            draggingLabelIndex = i;
            break;
        }
    }
    
    int stackIndex = [[draggingArr objectAtIndex:2] intValue];
    int bandIndex = [[draggingArr objectAtIndex:3] intValue];
    
    CGPoint point = [gestureRecognizer locationInView:self];
    point.x = draggingLabel.center.x;
    float yDiff = point.y - draggingLabel.center.y;
    [draggingLabel setCenter:point];
    
    // Find the type of layer we're dragging
    BOOL isStack = (bandIndex == -1);
    
    //  Check if currently dragging labels have switched order eachother (by y-coords)
    BOOL reorderedDragging = NO;    // whether or not dragging bands/stacks have been reordered
    int swappingLabelIndex = -1;    // index in _draggingLabels of band/stack being swapped with currently dragging band/stack
    int swappingBandIndex = -1;     // overall index of band being swapped
    int swappingStackIndex = -1;    // overall index of stack being swapped
    BOOL reorderUp = NO;            // YES if moving current band/stack above other, NO otherwise
    NSArray *swappingDragArr;       // information array for band/stack being swapped
    UILabel *swappingLab;           // label of band/stack being swapped
    if (yDiff < 0 && draggingLabelIndex > 0)
    {
        swappingLabelIndex = draggingLabelIndex-1;
        swappingDragArr = [_draggingLabels objectAtIndex:swappingLabelIndex];
        swappingLab = [swappingDragArr objectAtIndex:0];
        if (isStack)    swappingStackIndex = stackIndex-1;
        else            swappingBandIndex = bandIndex-1;
        reorderUp = YES;
    }
    else if (yDiff > 0 && draggingLabelIndex < [_draggingLabels count]-1)
    {
        swappingLabelIndex = draggingLabelIndex+1;
        swappingDragArr = [_draggingLabels objectAtIndex:swappingLabelIndex];
        swappingLab = [swappingDragArr objectAtIndex:0];
        if (isStack)    swappingStackIndex = stackIndex+1;
        else            swappingBandIndex = bandIndex+1;
        reorderUp = NO;
    }
    
    if (swappingLab &&
        ((reorderUp && (swappingLab.center.y > draggingLabel.center.y)) ||
        (!reorderUp && (swappingLab.center.y < draggingLabel.center.y))))
    {
        // Reorder
        reorderedDragging = YES;
        if (isStack)
        {
            [self swapStackLabels:stackIndex and:swappingStackIndex];
            [_drawDelegate reorderStacks:stackIndex withNewIndex:swappingStackIndex];
        }
        else
        {
            [self swapAllBandLabels:bandIndex and:swappingBandIndex skippingStack:stackIndex areBothDragging:YES];
            [_drawDelegate reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:swappingBandIndex];
        }
        
        // Set new index by replacing the dragging array
        NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
        NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
        NSMutableArray *mutaSwappingDragArr = [swappingDragArr mutableCopy];
        if (isStack)
        {
            [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:swappingStackIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:stackIndex]];            
        }
        else
        {
            [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:swappingBandIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:bandIndex]];
        }
        
        [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaSwappingDragArr];
        [mutaDraggingLabels replaceObjectAtIndex:swappingLabelIndex withObject:(NSArray *)mutaDraggingArr];
        _draggingLabels = (NSArray *)mutaDraggingLabels;
    }
    
    //  Handle swapping with non-dragging label
    if (!reorderedDragging)    
    {
        QueryData *data = [_dataDelegate delegateRequestsQueryData];
        float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
        int newIndex;
        if (isStack)
        {
            newIndex = point.y / stackHeight;
        }
        else
        {
            float normalY = point.y - (stackHeight * stackIndex);
            newIndex = normalY / (BAND_HEIGHT_P + BAND_SPACING);            
        }
        
        // Make sure new index is not currently being dragged
        BOOL beingDragged = NO;
        for (NSArray *a in _draggingLabels)
        {
            if ((isStack && ([[a objectAtIndex:2] intValue] == newIndex)) ||
                (!isStack && ([[a objectAtIndex:3] intValue] == newIndex)))
            {
                beingDragged = YES;
                break;
            }
        }
        
        // Reorder
        if (!isStack && (newIndex != bandIndex) && (newIndex >= 0) && !beingDragged)
        {                
            if ([_drawDelegate reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:newIndex])
            {
               [self swapAllBandLabels:bandIndex and:newIndex skippingStack:stackIndex areBothDragging:NO];
                
                // Set new index by replacing the dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
        else if (isStack && (newIndex != stackIndex) && (newIndex >= 0) && !beingDragged)
        {
            if ([_drawDelegate reorderStacks:stackIndex withNewIndex:newIndex])
            {
                [self swapStackLabels:stackIndex and:newIndex];
                
                // Set new index by replacing the dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
    }
}

/**
 *  Handle the resulting location of the dragged UILabel.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{    
    UILabel *draggingLabel = (UILabel *)[gestureRecognizer view];
    NSArray *draggingArr;
    for (NSArray *a in _draggingLabels)
    {
        if ([a objectAtIndex:0] == draggingLabel)
        {
            draggingArr = a;
            break;
        }
    }
    
    int stackIndex = [[draggingArr objectAtIndex:2] intValue];
    int bandIndex = [[draggingArr objectAtIndex:3] intValue];
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    
    // Find the type of layer we're dragging
    BOOL isStack = (bandIndex == -1);
    
    draggingLabel.opaque = YES;
    draggingLabel.backgroundColor = [UIColor blackColor];
    [self insertSubview:draggingLabel belowSubview:_bandZoomView];
    
    // Set new position for dropped layer based on its index
    if (isStack)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
        // Move label to rest
        float stackY = stackIndex * stackHeight;
        CGRect labelF = draggingLabel.frame;
        labelF.origin.y = stackY;
        draggingLabel.frame = labelF;
    }
    else
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
        // Move label to rest
        float stackY = stackIndex * stackHeight;
        float bandY = bandIndex * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
        CGRect labelF = draggingLabel.frame;
        labelF.origin.y = bandY;
        draggingLabel.frame = labelF;
    }
    
    // Remove dragging array now that it's finished
    NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
    [mutaDraggingLabels removeObjectIdenticalTo:draggingArr];
    _draggingLabels = (NSArray *)mutaDraggingLabels;
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
    // Drawing code
}
*/

@end
