//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentScrollView.h"
#import "PanelZoomView.h"
#import "PanelDrawView.h"
#import "BandLayer.h"
#import "QueryData.h"
#import "Meta.h"

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
                                    //  [x][2] corresponds to the index of the band being dragged (obviously optional if a stack is being dragged)
                                    //  [x][3] corresponds to the index of the stack being dragged or dragged inside
    enum UI_OBJECT _draggingType;   // Type of label currently being dragged
    NSArray *_stackLabelArray;      // Array of labels for each stack
    NSArray *_bandLabelArray;       // 2-dimensional array of labels for each band (indexed by stack then by band)
    float _bandFontSize;
    float _stackFontSize;
    
    UIView *_sideLabelView;          // View ocntaining all stack and band labels that moves horizontally with the landscape view
}

@synthesize dataDelegate = _dataDelegate;
@synthesize drawDelegate = _drawDelegate;
@synthesize panelZoomViews = _panelZoomViews;
@synthesize queryContentView = _queryContentView;

OBJC_EXPORT BOOL isPortrait;                // Global variable set in ContentViewController to specify device orientation
OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;            //
float LABEL_SPACING = (int)(((768.0 - BAND_WIDTH_P) * 3/4));

#pragma mark -
#pragma mark Initialization

- (id)initWithPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum
{
    if ((self = [super init])) 
    {        
        NSArray *newPanelZoomers = [[NSArray alloc] init];
        _panelZoomViews = newPanelZoomers;
        
        UIView *newContentView = [[UIView alloc] init];
        [self addSubview:newContentView];
        _queryContentView = newContentView;
        
        UIView *newLabelView = [[UIView alloc] init];
        [self addSubview:newLabelView];
        newLabelView.backgroundColor = [UIColor blackColor];
        _sideLabelView = newLabelView;
        
        self.delegate = self;
        
        [self sizeForPanelNum:panelNum stackNum:stackNum bandNum:bandNum];
        
        NSArray *newDraggingArr = [[NSArray alloc] init];
        _draggingLabels = newDraggingArr;
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		[self setBackgroundColor:[UIColor blackColor]];
        
        _draggingType = -1; // Not currently dragging
        
        _bandFontSize = 16.0f;
        _stackFontSize = 20.0f;
    }
    
    return self;
}

/**
 *  Resize this view to fit the specified number of panels, stacks, and bands.
 *  Should also inform all subviews to do the same.
 *
 *  panelNum is the number of panels in the new query
 *  stackNum is the number of stacks in the new query
 *  bandNum is the number of bands in the new query
 */
- (void)sizeForPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum
{
    // Scale UI layout constants
    float scale;
    float panelSpaceHoriz = 1024.0f - (768.0f - BAND_WIDTH_P);
    float landBandW;
    float contentHeight = ((bandNum * (BAND_HEIGHT_P + BAND_SPACING_P) + TIMELINE_HEIGHT_P) * stackNum) + TIMELINE_HEIGHT_P;
    // Check if content will be larger horizontally or vertically and size appropriately
    if ((BAND_WIDTH_P * panelNum) > contentHeight)
    {
        landBandW = panelSpaceHoriz / panelNum;
    }
    else
    {
        landBandW = BAND_WIDTH_P * ((768.0f - 44.0f) / contentHeight);
    }
    if (isPortrait)
    {
        scale = 1.0f;
    }
    else
    {
        scale = landBandW / BAND_WIDTH_P;
    }
    BAND_WIDTH = BAND_WIDTH_P * scale;
    BAND_HEIGHT = BAND_HEIGHT_P * scale;
    BAND_SPACING = BAND_SPACING_P * scale;
    TIMELINE_HEIGHT = BAND_HEIGHT_P * scale;
    
    if ([_panelZoomViews count] != panelNum)
    {        
        NSMutableArray *mutaPanels = [_panelZoomViews mutableCopy];
        // Move panels to new x-coords
        for (int i = 0; i < [mutaPanels count]; i++)
        {
            PanelZoomView *p = [mutaPanels objectAtIndex:i];
            CGRect frame = p.frame;
            frame.origin.x = LABEL_SPACING + (landBandW * i);
            p.frame = frame;
        }
        // Add additional panels
        int i;
        i = [mutaPanels count];
        while (i < panelNum)
        {            
            CGRect panelF = CGRectMake(LABEL_SPACING + (landBandW * i),  // Has to be rounded to an integer to truncate the trailing floating-point errors that reuslt for the calculation, otherwise drawing will not be exact in iOS's drawing coordinates (in order to offset them by precisely 0.5 units)
                                       0.0f,
                                       0.0f,
                                       0.0f);
            PanelZoomView *zoomView = [[PanelZoomView alloc] init];
            
            zoomView.frame = panelF;
            zoomView.panelDrawView.currentPanel = i;
            zoomView.panelDrawView.dataDelegate = _dataDelegate;
            [_queryContentView addSubview:zoomView];
            [mutaPanels addObject:zoomView];
            i++;
        }
        // Remove excess panels
        i = [mutaPanels count];
        while (i > panelNum)
        {            
            PanelZoomView *zoomView = [mutaPanels objectAtIndex:(i-1)];
            [zoomView removeFromSuperview];
            [mutaPanels removeObjectAtIndex:(i-1)];
            i--;
        }
        
        _panelZoomViews = (NSArray *)mutaPanels;
    }
    
    // Display/remove panels for differring views
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p removeFromSuperview];
    }
    if (isPortrait && panelNum != 0)
    {
        PanelZoomView *p = [_panelZoomViews objectAtIndex:0];
        [self addSubview:p];
    }
    else
    {
        for (PanelZoomView *p in _panelZoomViews)
        {
            [self addSubview:p];
        }
    }
    
    // Skip the rest of configuration if there are no panels
    if (panelNum == 0) return;
    
    // Resize all subviews
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p sizeForStackNum:stackNum bandNum:bandNum];
    }
    
    // Set size of content
    CGSize selfSize;
    if (isPortrait)
    {
        selfSize = ((PanelZoomView *)[_panelZoomViews objectAtIndex:0]).frame.size;
    }
    else
    {
        selfSize = CGSizeMake(1024.0f, 
                              ((PanelZoomView *)[_panelZoomViews objectAtIndex:0]).frame.size.height);
    }
    _queryContentView.frame = CGRectMake(0.0f, 0.0f, selfSize.width, selfSize.height);
    self.contentSize = selfSize;
    
    // Set zoom properties
    if (isPortrait)
    {
        for (PanelZoomView *p in _panelZoomViews)
        {
            p.bouncesZoom = YES;
            p.pinchGestureRecognizer.enabled = YES;
        }
        self.maximumZoomScale = 1.0f;
        self.minimumZoomScale = 1.0f;
    }
    else
    {
        for (PanelZoomView *p in _panelZoomViews)
        {
            p.bouncesZoom = NO;
            p.pinchGestureRecognizer.enabled = NO;
        }
        self.maximumZoomScale = 10.0f;
        self.minimumZoomScale = 1.0f;
    }
    
    self.drawDelegate = ((PanelZoomView *)[_panelZoomViews objectAtIndex:0]).panelDrawView;
    
	[self createLabels];
    
    // Draw new panels
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p.panelDrawView setNeedsDisplay];
    }
}

/**
 *  Display a specific panel in the array of panels, hiding the previously displayed panel.
 *  (assuming the previous panel is not statically visable)
 *
 *  panelNum is the array index of the panel to switch the view to (0-indexed)
 */
- (void)switchToPanel:(int)panelIndex
{
    NSLog(@"Here with index %d", panelIndex);
    
    if (panelIndex == -1) return;

    PanelZoomView *p = [_panelZoomViews objectAtIndex:0];
    if (panelIndex == p.panelDrawView.currentPanel)
        return;

    p.panelDrawView.currentPanel = panelIndex;
    p.panelDrawView.layer.contents = nil;
    [p.panelDrawView setNeedsDisplay];
}


#pragma mark -
#pragma mark Custom properties

/**
 *  Manage the data delegates of all underlying views
 */
- (void)setDataDelegate:(id<DataDelegate>)newDataDelegate
{
    _dataDelegate = newDataDelegate;
    
    for (PanelZoomView *p in _panelZoomViews)
    {
        p.panelDrawView.dataDelegate = newDataDelegate;
    }
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
	for (UIView *sub in _sideLabelView.subviews)
	{
		if ([sub isKindOfClass:[UILabel class]])
			[sub removeFromSuperview];
	}
    
    // Resize label view
    CGRect lFrame = CGRectMake(0.0f, 0.0f, 
                               LABEL_SPACING, 
                               self.contentSize.height);
    _sideLabelView.frame = lFrame;
	
    // Determine font sizing 
    //  (NOTE: The height box (including ascender and decender) of a font in equal to the point size - 1.0)
    _stackFontSize = (TIMELINE_HEIGHT + 1.0f < 20.0f ? TIMELINE_HEIGHT + 1.0f : 20.0f);
    _bandFontSize = (BAND_HEIGHT + 1.0f < 16.0f ? BAND_HEIGHT + 1.0f : 16.0f);
    
	// Create new labels
	float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    NSMutableArray *newStackLabels = [[NSMutableArray alloc] init];
    NSMutableArray *newBandLabels = [[NSMutableArray alloc] init];
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
		CGRect labelF = CGRectMake(16.0f, stackY, 128.0f, TIMELINE_HEIGHT);
		UILabel *stackL = [[UILabel alloc] initWithFrame:labelF];
		[stackL setTextAlignment:UITextAlignmentLeft];
		[stackL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize]];
        [stackL setBackgroundColor:[UIColor clearColor]];
        [stackL setTextColor:[UIColor whiteColor]];
		NSString *stackM = [(Meta *)[(NSArray *)[data.selectedMetas objectForKey:@"Stacks"] objectAtIndex:i] name];
		[stackL setText:stackM];
        
        UILongPressGestureRecognizer* sDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        sDragGesture.delegate = self;
        [sDragGesture setNumberOfTouchesRequired:1];
        [stackL addGestureRecognizer:sDragGesture];
        [stackL setUserInteractionEnabled:YES];
        
		[_sideLabelView addSubview:stackL];
        [newStackLabels addObject:stackL];
		
        NSMutableArray *currentBandLabels = [[NSMutableArray alloc] init];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT);
			UILabel *bandL = [[UILabel alloc] initWithFrame:labelF];
			[bandL setTextAlignment:UITextAlignmentRight];
            [bandL setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize]];
            [bandL setBackgroundColor:[UIColor clearColor]];
            [bandL setTextColor:[UIColor whiteColor]];
			NSString *meta = [(Meta *)[(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j] name];
			[bandL setText:meta];
            
            UILongPressGestureRecognizer* bDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
            bDragGesture.delegate = self;
            [bDragGesture setNumberOfTouchesRequired:1];
            [bandL addGestureRecognizer:bDragGesture];
            [bandL setUserInteractionEnabled:YES];
            
			[_sideLabelView addSubview:bandL];
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
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    
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
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    NSMutableArray *bandLabelsMutable = [_bandLabelArray mutableCopy];
    for (int i = 0; i < [bandLabelsMutable count]; i++)
    {
        float stackY = i * stackHeight;
        NSMutableArray *arrMutable = [bandLabelsMutable objectAtIndex:i];
        
        // Move all labels corresponding to the label currently being dragged
        UILabel *draggingLabel = [arrMutable objectAtIndex:draggingIndex];
        if (i != skipStackIndex)
        {
            float draggingY = otherIndex * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT + stackY;
            CGRect draggingF = draggingLabel.frame;
            draggingF.origin.y = draggingY;
            draggingLabel.frame = draggingF;
        }
        
        // Move labels corresponding to the label not being dragged that is being swapped
        UILabel *otherLabel = [arrMutable objectAtIndex:otherIndex];
        if (!bothDragging || i != skipStackIndex)
        {
            float otherY = draggingIndex * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT + stackY;
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
    NSMutableArray *draggingLabelArr = [[NSMutableArray alloc] init];
    UILabel *draggingLabel;
    enum UI_OBJECT draggingLabelType = -1;
    for (int i = 0; i < [_stackLabelArray count]; i++)
    {
        draggingLabel = [_stackLabelArray objectAtIndex:i];
        if (CGRectContainsPoint(draggingLabel.frame, point))
        {
            [draggingLabelArr addObject:draggingLabel];
            [draggingLabelArr addObject:[_drawDelegate getStackLayerForStack:i]];
            [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];
            [draggingLabelArr addObject:[NSNumber numberWithInt:i]];
            [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // temp placeholder for panel dragging
            
            draggingLabelType = STACK;
            
            break;
        }
    }
    // If the label isn't a stack label, check band labels
    if (draggingLabelType == -1)
    {
        for (int i = 0; i < [_bandLabelArray count]; i++)
        {   
            BOOL found = NO;
            NSArray *bandArray = [_bandLabelArray objectAtIndex:i];
            for (int j = 0; j < [bandArray count]; j++)
            {
                draggingLabel = [bandArray objectAtIndex:j];
                if (CGRectContainsPoint(draggingLabel.frame, point))
                {
                    [draggingLabelArr addObject:draggingLabel];
                    [draggingLabelArr addObject:[_drawDelegate getBandLayerForStack:i band:j]];
                    [draggingLabelArr addObject:[NSNumber numberWithInt:j]];
                    [draggingLabelArr addObject:[NSNumber numberWithInt:i]];
                    [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // temp placeholder for panel dragging
                    
                    draggingLabelType = BAND;
                    
                    found = YES;
                    break;
                }
            }
            if (found) break;
        }
    }
    
    if (_draggingType == -1)
    {
        _draggingType = draggingLabelType;
    }
    
    // Check to see if the selected label is an illegal label to be dragged
    //  i.e. if dragging a band, only bands are being dragged, and the band is within the stack and panel the others are being dragged within
    if (
        _draggingType != draggingLabelType 
        ||
        (draggingLabelType == BAND && [_draggingLabels count] > 0 &&
            ([[[_draggingLabels objectAtIndex:0] objectAtIndex:3] intValue] != [[draggingLabelArr objectAtIndex:3] intValue]))
        )
    {
        NSLog(@"Dragging types do not match, cancelling startDrag!!");
        return;
    }
    
    if (draggingLabelType == BAND)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize + 4.0f]];
    }
    else if (draggingLabelType == STACK)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize + 4.0f]];
    }
    
    // Insert into dragging array ordered based on y-coord of all dragging labels
    NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
    int l;
    for (l = 0; l < [mutaDraggingLabels count]; l++)
    {
        UILabel *currentL = [[mutaDraggingLabels objectAtIndex:l] objectAtIndex:0];
        
        if (draggingLabel && currentL.frame.origin.y > draggingLabel.frame.origin.y) break;
    }
    [mutaDraggingLabels insertObject:draggingLabelArr atIndex:l];
    
    _draggingLabels = (NSArray *)mutaDraggingLabels;
}

/**
 *  Handle the moving of the UILabel corresponding to a band or stack.
 *  Check if re-ordering is necessary and if so, re-order.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer
{    
//    [CATransaction begin];
//    [CATransaction setAnimationDuration:0.1f];
//    [CATransaction setDisableActions: YES];
    
    // We assume that the label being dragged has been added to the _draggingLabels array in startDrag()
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
    if (draggingLabelIndex == -1)
    {
        return;
    }
    
    int stackIndex = [[draggingArr objectAtIndex:3] intValue];
    int bandIndex = [[draggingArr objectAtIndex:2] intValue];
    
    // Find the type of layer we're dragging
    enum UI_OBJECT draggingLabelType = -1;
    if (bandIndex == -1)
    {
        draggingLabelType = STACK;
    }
    else
    {
        draggingLabelType = BAND;
    }
    
    // Ignore if illegal label to drag
    if (_draggingType != draggingLabelType)
    {
        return;
    }
    
    // Move label
    CGPoint point = [gestureRecognizer locationInView:self];
    point.x = draggingLabel.center.x;
    float yDiff = point.y - draggingLabel.center.y;
    [draggingLabel setCenter:point];
    
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
        if (draggingLabelType == STACK)
            swappingStackIndex = stackIndex-1;
        else
            swappingBandIndex = bandIndex-1;
        reorderUp = YES;
    }
    else if (yDiff > 0 && draggingLabelIndex < [_draggingLabels count]-1)
    {
        swappingLabelIndex = draggingLabelIndex+1;
        swappingDragArr = [_draggingLabels objectAtIndex:swappingLabelIndex];
        swappingLab = [swappingDragArr objectAtIndex:0];
        if (draggingLabelType == STACK)
            swappingStackIndex = stackIndex+1;
        else
            swappingBandIndex = bandIndex+1;
        reorderUp = NO;
    }
    
    if (swappingLab &&
        ((reorderUp && (swappingLab.center.y > draggingLabel.center.y)) ||
        (!reorderUp && (swappingLab.center.y < draggingLabel.center.y))))
    {
        // Reorder
        reorderedDragging = YES;
        if (draggingLabelType == STACK)
        {
            [self swapStackLabels:stackIndex and:swappingStackIndex];
            for (PanelZoomView *p in _panelZoomViews)
                [p.panelDrawView reorderStack:stackIndex withNewIndex:swappingStackIndex];
        }
        else
        {
            [self swapAllBandLabels:bandIndex and:swappingBandIndex skippingStack:stackIndex areBothDragging:YES];
            for (PanelZoomView *p in _panelZoomViews)
                [p.panelDrawView reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:swappingBandIndex];
        }
        
        // Set new index by replacing the dragging array
        NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
        NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
        NSMutableArray *mutaSwappingDragArr = [swappingDragArr mutableCopy];
        if (draggingLabelType == STACK)
        {
            [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:swappingStackIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:stackIndex]];            
        }
        else
        {
            [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:swappingBandIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:bandIndex]];
        }
        
        [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaSwappingDragArr];
        [mutaDraggingLabels replaceObjectAtIndex:swappingLabelIndex withObject:(NSArray *)mutaDraggingArr];
        _draggingLabels = (NSArray *)mutaDraggingLabels;
    }
    
    //  Handle swapping with non-dragging label
    if (!reorderedDragging)    
    {
        QueryData *data = [_dataDelegate delegateRequestsQueryData];
        float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
        int newIndex;
        if (draggingLabelType == STACK)
        {
            newIndex = point.y / stackHeight;
        }
        else
        {
            float normalY = point.y - (stackHeight * stackIndex);
            newIndex = normalY / (BAND_HEIGHT + BAND_SPACING);            
        }
        
        // Make sure new index is not currently being dragged
        BOOL beingDragged = NO;
        for (NSArray *a in _draggingLabels)
        {
            if ((draggingLabelType == STACK && ([[a objectAtIndex:3] intValue] == newIndex)) ||
                (draggingLabelType == BAND && ([[a objectAtIndex:2] intValue] == newIndex)))
            {
                beingDragged = YES;
                break;
            }
        }
        
        // Reorder
        if (draggingLabelType == BAND && (newIndex != bandIndex) && (newIndex >= 0) && !beingDragged)
        {                
            if ([_drawDelegate reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:newIndex])
            {
                for (int i = 1; i < [_panelZoomViews count]; i++)
                {
                    PanelZoomView *p = [_panelZoomViews objectAtIndex:i];
                    [p.panelDrawView reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:newIndex];
                }
                [self swapAllBandLabels:bandIndex and:newIndex skippingStack:stackIndex areBothDragging:NO];
                
                // Set new index by replacing the dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
        else if (draggingLabelType == STACK && (newIndex != stackIndex) && (newIndex >= 0) && !beingDragged)
        {
            if ([_drawDelegate reorderStack:stackIndex withNewIndex:newIndex])
            {
                for (int i = 1; i < [_panelZoomViews count]; i++)
                {
                    PanelZoomView *p = [_panelZoomViews objectAtIndex:i];
                    [p.panelDrawView reorderStack:stackIndex withNewIndex:newIndex];
                }
                [self swapStackLabels:stackIndex and:newIndex];
                
                // Set new index by replacing the dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
    }
    
//    [CATransaction commit];
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
    if (!draggingArr)
    {
        return;
    }
    
    int stackIndex = [[draggingArr objectAtIndex:3] intValue];
    int bandIndex = [[draggingArr objectAtIndex:2] intValue];
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    
    // Find the type of layer we're dragging
    BOOL isStack = (bandIndex == -1);
    
    // Set new position for dropped layer based on its index
    CGRect labelF = draggingLabel.frame;
    if (isStack)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize]];
        // Move label to rest
        float stackY = stackIndex * stackHeight;
        labelF.origin.y = stackY;
    }
    else
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize]];
        // Move label to rest
        float stackY = stackIndex * stackHeight;
        float bandY = bandIndex * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT + stackY;
        labelF.origin.y = bandY;
    }
    draggingLabel.frame = labelF;
    
    // Remove dragging array now that it's finished
    NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
    [mutaDraggingLabels removeObjectIdenticalTo:draggingArr];
    _draggingLabels = (NSArray *)mutaDraggingLabels;
    
    // If last of the labels being dragged, reset the status to dragging no labels
    if ([_draggingLabels count] == 0)
    {
        NSLog(@"Resetting dragging type!!!");
        _draggingType = -1;
    }
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


#pragma mark -
#pragma mark Drawing

/**
 *  Basic override for zooming in UIScrollViews
 */
- (UIView *)viewForZoomingInScrollView:(ContentScrollView *)scrollView 
{	
	return _queryContentView;
}

/**
 *  Overridden so that the contentView knows when transformations have completed
 */
- (void)scrollViewDidEndZooming:(PanelZoomView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p.panelDrawView setNeedsDisplay];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
//    float temp_BAND_WIDTH = BAND_WIDTH * scrollView.zoomScale;
    float temp_BAND_HEIGHT = BAND_HEIGHT * scrollView.zoomScale;
    float temp_BAND_SPACING = BAND_SPACING * scrollView.zoomScale;
    float temp_TIMELINE_HEIGHT = TIMELINE_HEIGHT * scrollView.zoomScale;
    
    // Resize panels
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p zoomToScale:scrollView.zoomScale];
    }
    
    // Resize labels
    CGRect newLabelF = _sideLabelView.frame;
    newLabelF.size.height = _queryContentView.frame.size.height;
    _sideLabelView.frame = newLabelF;
    
    _stackFontSize = (temp_TIMELINE_HEIGHT + 1.0f < 20.0f ? temp_TIMELINE_HEIGHT + 1.0f : 20.0f);
    _bandFontSize = (temp_BAND_HEIGHT + 1.0f < 16.0f ? temp_BAND_HEIGHT + 1.0f : 16.0f);
    
    float stackHeight = (data.bandNum-1.0f) * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_BAND_HEIGHT + temp_TIMELINE_HEIGHT;
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
		CGRect labelF = CGRectMake(16.0f, stackY, 128.0f, temp_TIMELINE_HEIGHT);
		UILabel *stackL = [_stackLabelArray objectAtIndex:i];
        stackL.frame = labelF;
        stackL.font = [UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize];
		
        NSArray *currentBandLabels = [_bandLabelArray objectAtIndex:i];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_TIMELINE_HEIGHT + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, temp_BAND_HEIGHT);
			UILabel *bandL = [currentBandLabels objectAtIndex:j];
            bandL.frame = labelF;
            bandL.font = [UIFont fontWithName:@"Helvetica" size:_bandFontSize];
        }
    }
}

/**
 *  Enable the labels to scroll with the scrollView
 */
- (void)scrollViewDidScroll:(ContentScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    CGRect newFrame = _sideLabelView.frame;
    newFrame.origin.x = offset.x;
    _sideLabelView.frame = newFrame;
    [self bringSubviewToFront:_sideLabelView];
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
