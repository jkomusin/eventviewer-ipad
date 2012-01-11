//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentScrollView.h"
#import "DraggableLabel.h"
#import "PanelZoomView.h"
#import "PanelDrawView.h"
#import "BandLayer.h"
#import "QueryData.h"
#import "Meta.h"

@interface ContentScrollView ()
- (void)createLabels;
- (void)swapAllBandLabels:(int)draggingIndex and:(int)otherIndex skippingStack:(int)skipStackIndex areBothDragging:(BOOL)bothDragging;
- (void)swapStackLabels:(int)draggingIndex and:(int)otherIndex;
- (void)swapPanelLabels:(int)draggingIndex and:(int)otherIndex;
@end

@implementation ContentScrollView
{
	id<DataDelegate> dataDelegate;
    id<DrawDelegate> drawDelegate;
    
    NSArray *_draggingLabels;       // 2-dimensional array of labels and their associated information as such:
                                    //  Index of outer array corresponds to each dragging label
                                    //  [x][0] corresponds to the DraggableLabel being dragged
                                    //  [x][1] corresponds to the layer being dragged (may be a Panel, Stack, or Band, should check)
                                    //  [x][2] corresponds to the index of the band being dragged (obviously optional if a stack is being dragged)
                                    //  [x][3] corresponds to the index of the stack being dragged or dragged inside
    enum UI_OBJECT _draggingType;   // Type of label currently being dragged
    NSArray *_panelLabelArray;      // Array of labels for each panel
    NSArray *_stackLabelArray;      // Array of labels for each stack
    NSArray *_bandLabelArray;       // 2-dimensional array of labels for each band (indexed by stack then by band)
    
    float _bandFontSize;            // Respective sized of label fonts
    float _stackFontSize;           //
    float _panelFontSize;           //
    
    UIView *_topLabelView;          // View containing all panel labels that moves vertically with the landscae view
    UIView *_sideLabelView;         // View containing all stack and band labels that moves horizontally with the landscape view
    
    float ZOOMED_BAND_WIDTH;        // UI layout parameters normalized for the current zoomScale of the CSV for convenience
    float ZOOMED_BAND_HEIGHT;       //
    float ZOOMED_BAND_SPACING;      //
    float ZOOMED_TIMELINE_HEIGHT;   //
}

@synthesize dataDelegate = _dataDelegate;
@synthesize drawDelegate = _drawDelegate;
@synthesize panelZoomViews = _panelZoomViews;
@synthesize queryContentView = _queryContentView;

OBJC_EXPORT BOOL isPortrait;                // Global variable set in ContentViewController to specify device orientation
OBJC_EXPORT BOOL isLeftHanded;              // Global variable set in ContentViewController to specify user-handed-ness
OBJC_EXPORT float BAND_HEIGHT;              // Globals set to sizes dependant on number of panels and size of display,
OBJC_EXPORT float BAND_WIDTH;               //  for use in scaling and fitting entire display into view in landscape.
OBJC_EXPORT float BAND_SPACING;             //  May be assumed to be the normalized, un-zoomed sizes in both landscape
OBJC_EXPORT float TIMELINE_HEIGHT;          //  and portrait.

// Spacing for panel, stack, and band label views
float SIDE_LABEL_SPACING = (int)(((768.0 - BAND_WIDTH_P) * 3.0f/4.0f));   // The extra 1/4 left out of this provides an end cap on the opposite side of the panels
float TOP_LABEL_SPACING = 50.0f;

#pragma mark -
#pragma mark Initialization

- (id)initWithPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum
{
    if ((self = [super init])) 
    {        
        // Panels
        NSArray *newPanelZoomers = [[NSArray alloc] init];
        _panelZoomViews = newPanelZoomers;
        
        // Content view
        UIView *newContentView = [[UIView alloc] init];
        [self addSubview:newContentView];
        _queryContentView = newContentView;
        
        // Label views
        UIView *newTopLabelView = [[UIView alloc] init];
        [self addSubview:newTopLabelView];
        newTopLabelView.backgroundColor = [UIColor blackColor];
        _topLabelView = newTopLabelView;
        UIView *newSideLabelView = [[UIView alloc] init];
        [self addSubview:newSideLabelView];
        newSideLabelView.backgroundColor = [UIColor blackColor];
        _sideLabelView = newSideLabelView;
        
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
        _panelFontSize = 24.0f;
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
        landBandW = BAND_WIDTH_P * ((768.0f - 44.0f - TOP_LABEL_SPACING) / contentHeight);
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
    ZOOMED_BAND_WIDTH = BAND_WIDTH;
    BAND_HEIGHT = BAND_HEIGHT_P * scale;
    ZOOMED_BAND_HEIGHT = BAND_HEIGHT;
    BAND_SPACING = BAND_SPACING_P * scale;
    ZOOMED_BAND_SPACING = BAND_SPACING;
    TIMELINE_HEIGHT = BAND_HEIGHT_P * scale;
    ZOOMED_TIMELINE_HEIGHT = TIMELINE_HEIGHT;
    
    NSMutableArray *mutaPanels = [_panelZoomViews mutableCopy];
    // Move panels to new coords
    for (int i = 0; i < [mutaPanels count]; i++)
    {
        PanelZoomView *p = [mutaPanels objectAtIndex:i];
        CGRect frame = p.frame;
        if (isLeftHanded)   frame.origin.x = SIDE_LABEL_SPACING + (landBandW * i);
        if (!isLeftHanded)  frame.origin.x = (1.0f/4.0f * (768.0f - BAND_WIDTH_P)) + (landBandW * i);
        if (isPortrait) frame.origin.y = 0.0f;
        else            frame.origin.y = TOP_LABEL_SPACING;
        p.frame = frame;
    }
    
    if ([_panelZoomViews count] != panelNum)
    {        
        // Add additional panels
        int i;
        i = [mutaPanels count];
        while (i < panelNum)
        {            
            CGRect panelF = CGRectMake((1.0f/4.0f * (768.0f - BAND_WIDTH_P)) + (landBandW * i),
                                       0.0f,
                                       0.0f,
                                       0.0f);
            if (isLeftHanded)   panelF.origin.x = SIDE_LABEL_SPACING + (landBandW * i);
            if (!isPortrait) panelF.origin.y = TOP_LABEL_SPACING;
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
                              ((PanelZoomView *)[_panelZoomViews objectAtIndex:0]).frame.size.height + TOP_LABEL_SPACING);
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
    
    // Create  labels and handle label view displaying
    [self createLabels];
    if (isPortrait) [_topLabelView removeFromSuperview];
    else            [self addSubview:_topLabelView];
    
    // Draw new panels
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p.panelDrawView zoomToScale:1.0f];
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
	
    // Remove old panel labels
    for (UIView *sub in _topLabelView.subviews)
    {
        if ([sub isKindOfClass:[UILabel class]])
            [sub removeFromSuperview];
    }
    // Resize top label view
    CGRect lTopFrame = CGRectMake((1.0f/4.0f * (768.0f - BAND_WIDTH_P)), 
                                  0.0f, 
                                  BAND_WIDTH * data.panelNum, 
                                  TOP_LABEL_SPACING);
    if (isLeftHanded)   lTopFrame.origin.x = SIDE_LABEL_SPACING;
    _topLabelView.frame = lTopFrame;
    
	// Remove old band & stack labels
	for (UIView *sub in _sideLabelView.subviews)
	{
		if ([sub isKindOfClass:[UILabel class]])
			[sub removeFromSuperview];
	}
    // Resize side label view
    CGRect lSideFrame = CGRectMake(self.frame.size.width - SIDE_LABEL_SPACING,    
                                   0.0f, //-1024.0f,    // To cover excess when zoom-bouncing
                                   SIDE_LABEL_SPACING, 
                                   self.contentSize.height);// + 1024.0f);  // ^^^
    if (isLeftHanded)   lSideFrame.origin.x = 0.0f;
    _sideLabelView.frame = lSideFrame;
    
    // Determine font sizing 
    //  (NOTE: The height box (including ascender and decender) of a font in equal to the point size - 1.0)
//    _panelFontSize = 
    _stackFontSize = (TIMELINE_HEIGHT + 1.0f < 20.0f ? TIMELINE_HEIGHT + 1.0f : 20.0f);
    _bandFontSize = (BAND_HEIGHT + 1.0f < 16.0f ? BAND_HEIGHT + 1.0f : 16.0f);
    
    // Create new panel labels
    NSMutableArray *newPanelLabels = [[NSMutableArray alloc] init];
    for (int i = 0; i < data.panelNum; i++)
    {
        CGRect labelF = CGRectMake((BAND_WIDTH * i), 0.0f, BAND_WIDTH, 50.0f);
        DraggableLabel *panelL = [[DraggableLabel alloc] initWithFrame:labelF];
        [panelL setTextAlignment:UITextAlignmentCenter];
        [panelL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_panelFontSize]];
        [panelL setBackgroundColor:[UIColor clearColor]];
        [panelL setTextColor:[UIColor whiteColor]];
        NSString *panelM = [(Meta *)[(NSArray *)[data.selectedMetas objectForKey:@"Panels"] objectAtIndex:i] name];
        [panelL setText:panelM];
        
        UILongPressGestureRecognizer* pDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        pDragGesture.delegate = self;
        [pDragGesture setNumberOfTouchesRequired:1];
        [pDragGesture setMinimumPressDuration:0.1f];
        [panelL addGestureRecognizer:pDragGesture];
        [panelL setUserInteractionEnabled:YES];
        
        [_topLabelView addSubview:panelL];
        [newPanelLabels addObject:panelL];
    }
    
    _panelLabelArray = (NSArray *)newPanelLabels;
    
	// Create new stack & band labels
	float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    NSMutableArray *newStackLabels = [[NSMutableArray alloc] init];
    NSMutableArray *newBandLabels = [[NSMutableArray alloc] init];
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY;
        if (isPortrait) stackY = stackHeight * i;// + 1024.0f;
        else            stackY = TOP_LABEL_SPACING + stackHeight * i;// + 1024.0f;
		CGRect labelF = CGRectMake(16.0f, stackY, 128.0f, TIMELINE_HEIGHT);
		DraggableLabel *stackL = [[DraggableLabel alloc] initWithFrame:labelF];
		[stackL setTextAlignment:UITextAlignmentLeft];
		[stackL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize]];
        [stackL setBackgroundColor:[UIColor clearColor]];
        [stackL setTextColor:[UIColor whiteColor]];
		NSString *stackM = [(Meta *)[(NSArray *)[data.selectedMetas objectForKey:@"Stacks"] objectAtIndex:i] name];
        NSString *newStackM = [NSString stringWithFormat:@"\t\t\t%@", stackM];
		[stackL setText:newStackM];
        
        UILongPressGestureRecognizer* sDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        sDragGesture.delegate = self;
        [sDragGesture setNumberOfTouchesRequired:1];
        [sDragGesture setMinimumPressDuration:0.1f];
        [stackL addGestureRecognizer:sDragGesture];
        [stackL setUserInteractionEnabled:YES];
        
		[_sideLabelView addSubview:stackL];
        [newStackLabels addObject:stackL];
		
        NSMutableArray *currentBandLabels = [[NSMutableArray alloc] init];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, BAND_HEIGHT);
			DraggableLabel *bandL = [[DraggableLabel alloc] initWithFrame:labelF];
			[bandL setTextAlignment:UITextAlignmentRight];
            [bandL setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize]];
            [bandL setBackgroundColor:[UIColor clearColor]];
            [bandL setTextColor:[UIColor whiteColor]];
			NSString *meta = [(Meta *)[(NSArray *)[data.selectedMetas objectForKey:@"Bands"] objectAtIndex:j] name];
			[bandL setText:meta];
            
            UILongPressGestureRecognizer* bDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
            bDragGesture.delegate = self;
            [bDragGesture setNumberOfTouchesRequired:1];
            [bDragGesture setMinimumPressDuration:0.1f];
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

- (void)swapPanelLabels:(int)draggingIndex and:(int)otherIndex
{
    DraggableLabel *draggingLabel = [_panelLabelArray objectAtIndex:draggingIndex];
    DraggableLabel *otherLabel = [_panelLabelArray objectAtIndex:otherIndex];
    
    float panelX = (1.0f/4.0f * (768.0f - BAND_WIDTH_P)) + draggingIndex * ZOOMED_BAND_WIDTH;
    if (isLeftHanded)   panelX = SIDE_LABEL_SPACING + draggingIndex * ZOOMED_BAND_WIDTH;
    CGRect labelF = otherLabel.frame;
    labelF.origin.x = panelX;
    otherLabel.frame = labelF;
    
    // Reorder labels in array
    NSMutableArray *mutaPanelLabels = [_panelLabelArray mutableCopy];
    [mutaPanelLabels replaceObjectAtIndex:draggingIndex withObject:otherLabel];
    [mutaPanelLabels replaceObjectAtIndex:otherIndex withObject:draggingLabel];
    
    _panelLabelArray = (NSArray *)mutaPanelLabels;
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
    float stackHeight = (data.bandNum-1.0f) * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_BAND_HEIGHT + ZOOMED_TIMELINE_HEIGHT;
    
    DraggableLabel *draggingLabel = [_stackLabelArray objectAtIndex:draggingIndex];
    DraggableLabel *otherLabel = [_stackLabelArray objectAtIndex:otherIndex];
    
    float stackY;
    if (isPortrait) stackY = draggingIndex * stackHeight;
    else            stackY = draggingIndex * stackHeight + TOP_LABEL_SPACING;
    CGRect labelF = otherLabel.frame;
    labelF.origin.y = stackY;
    otherLabel.frame = labelF;
    
    // Reorder labels in array
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
    float stackHeight = (data.bandNum-1.0f) * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_BAND_HEIGHT + ZOOMED_TIMELINE_HEIGHT;
    NSMutableArray *bandLabelsMutable = [_bandLabelArray mutableCopy];
    for (int i = 0; i < [bandLabelsMutable count]; i++)
    {
        float stackY;
        if (isPortrait) stackY = i * stackHeight;
        else            stackY = i * stackHeight + TOP_LABEL_SPACING;
        NSMutableArray *arrMutable = [bandLabelsMutable objectAtIndex:i];
        
        // Move all labels corresponding to the label currently being dragged
        DraggableLabel *draggingLabel = [arrMutable objectAtIndex:draggingIndex];
        if (i != skipStackIndex)
        {
            float draggingY = otherIndex * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_TIMELINE_HEIGHT + stackY;
            CGRect draggingF = draggingLabel.frame;
            draggingF.origin.y = draggingY;
            draggingLabel.frame = draggingF;
        }
        
        // Move labels corresponding to the label not being dragged that is being swapped
        DraggableLabel *otherLabel = [arrMutable objectAtIndex:otherIndex];
        if (!bothDragging || i != skipStackIndex)
        {
            float otherY = draggingIndex * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_TIMELINE_HEIGHT + stackY;
            CGRect otherF = otherLabel.frame;
            otherF.origin.y = otherY;
            otherLabel.frame = otherF;
        }
            
        // Reorder labels in array
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
    // Find label and related layer
    NSMutableArray *draggingLabelArr = [[NSMutableArray alloc] init];
    DraggableLabel *draggingLabel = (DraggableLabel *)[gestureRecognizer view];
    enum UI_OBJECT draggingLabelType = -1;
    // Check panel labels
    for (int i = 0; i < [_panelLabelArray count]; i++)
    {
        if (draggingLabel == [_panelLabelArray objectAtIndex:i])
        {
            [draggingLabelArr addObject:draggingLabel];
            [draggingLabelArr addObject:[_panelZoomViews objectAtIndex:i]];
            [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // band index is null as a panel pertains to all bands
            [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];    // stack index is null as a panel pertains to all stacks
            [draggingLabelArr addObject:[NSNumber numberWithInt:i]];   // panel index
            
            draggingLabelType = PANEL;
            
            break;
        }
    }
    // If the label isn't a panel, check stack labels
    if (draggingLabelType == -1)
    {
        for (int i = 0; i < [_stackLabelArray count]; i++)
        {
            if (draggingLabel == [_stackLabelArray objectAtIndex:i])
            {
                [draggingLabelArr addObject:draggingLabel];
                [draggingLabelArr addObject:[_drawDelegate getStackLayerForStack:i]];
                [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // band index is null as a stack pertains to all bands
                [draggingLabelArr addObject:[NSNumber numberWithInt:i]];    // stack index
                [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // panel index is null as a stack pertains to all panels
                
                draggingLabelType = STACK;
                
                break;
            }
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
                if (draggingLabel == [bandArray objectAtIndex:j])
                {
                    [draggingLabelArr addObject:draggingLabel];
                    [draggingLabelArr addObject:[_drawDelegate getBandLayerForStack:i band:j]];
                    [draggingLabelArr addObject:[NSNumber numberWithInt:j]];    // band index
                    [draggingLabelArr addObject:[NSNumber numberWithInt:i]];    // stack index
                    [draggingLabelArr addObject:[NSNumber numberWithInt:-1]];   // panel index is null as a band pertains to all panels
                    
                    draggingLabelType = BAND;
                    
                    found = YES;
                    break;
                }
            }
            if (found) break;
        }
    }
    
    // If this is the only label currently (assumed if _draggingType is null), set the type
    if (_draggingType == -1)
    {
        _draggingType = draggingLabelType;
    }
    
    // Check to see if the selected label is an illegal label to be dragged
    //  NOTE: If dragging a band, only bands are being dragged, and the band is within the stack and panel the others are being dragged within
    if (_draggingType != draggingLabelType 
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
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize + 8.0f]];
    }
    else if (draggingLabelType == STACK)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize + 8.0f]];
    }
    else if (draggingLabelType == PANEL)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_panelFontSize + 8.0f]];
    }
    
    // Insert into dragging array ordered based on:
    //  y-coord of all dragging labels if band/stack
    //  x-coord of all dragging labels if panel
    NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
    int l;
    for (l = 0; l < [mutaDraggingLabels count]; l++)
    {
        DraggableLabel *currentL = [[mutaDraggingLabels objectAtIndex:l] objectAtIndex:0];
        
        if (((draggingLabelType == BAND || draggingLabelType == STACK) && draggingLabel && (currentL.frame.origin.y > draggingLabel.frame.origin.y))
            ||
            (draggingLabelType == PANEL && draggingLabel && (currentL.frame.origin.x > draggingLabel.frame.origin.x))) 
        {
            break;
        }
    }
    [mutaDraggingLabels insertObject:(NSArray *)draggingLabelArr atIndex:l];
    
    _draggingLabels = (NSArray *)mutaDraggingLabels;
}

/**
 *  Handle the moving of the DraggingLabel corresponding to a band, stack, or panel.
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
    DraggableLabel *draggingLabel = (DraggableLabel *)[gestureRecognizer view];
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
    
    int panelIndex = [[draggingArr objectAtIndex:4] intValue];
    int stackIndex = [[draggingArr objectAtIndex:3] intValue];
    int bandIndex = [[draggingArr objectAtIndex:2] intValue];
    
    // Find the type of layer we're dragging
    enum UI_OBJECT draggingLabelType = -1;
    if (bandIndex == -1 && stackIndex == -1)
    {
        draggingLabelType = PANEL;
    }
    else if (bandIndex == -1)
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
    if (draggingLabelType == PANEL) point.y = draggingLabel.center.y;
    else                            point.x = draggingLabel.center.x;
    float yDiff = point.y - draggingLabel.center.y;
    float xDiff = point.x - draggingLabel.center.x;
    [draggingLabel setCenter:point];
    
    //  Check if currently dragging labels have switched order eachother (by y-coords)
    int swappingLabelIndex = -1;    // index in _draggingLabels of band/stack/panel being swapped with currently dragging band/stack/panel
    int swappingBandIndex = -1;     // overall index of band being swapped
    int swappingStackIndex = -1;    // overall index of stack being swapped
    int swappingPanelIndex = -1;    // overall index of panel being swapped
    BOOL reorderUp = NO;            // YES if moving current band/stack above other or panel to the left, NO otherwise
    NSArray *swappingDragArr;       // information array for band/stack/panel being swapped
    DraggableLabel *swappingLab;           // label of band/stack/panel being swapped
    if ((yDiff < 0 || xDiff < 0) && draggingLabelIndex > 0)
    {
        swappingLabelIndex = draggingLabelIndex-1;
        swappingDragArr = [_draggingLabels objectAtIndex:swappingLabelIndex];
        swappingLab = [swappingDragArr objectAtIndex:0];
        if (draggingLabelType == PANEL)
            swappingPanelIndex = panelIndex-1;
        else if (draggingLabelType == STACK)
            swappingStackIndex = stackIndex-1;
        else if (draggingLabelType == BAND)
            swappingBandIndex = bandIndex-1;
        reorderUp = YES;
    }
    else if ((yDiff > 0 || xDiff > 0) && draggingLabelIndex < [_draggingLabels count]-1)
    {
        swappingLabelIndex = draggingLabelIndex+1;
        swappingDragArr = [_draggingLabels objectAtIndex:swappingLabelIndex];
        swappingLab = [swappingDragArr objectAtIndex:0];
        if (draggingLabelType == PANEL)
            swappingPanelIndex = panelIndex+1;
        else if (draggingLabelType == STACK)
            swappingStackIndex = stackIndex+1;
        else if (draggingLabelType == BAND)
            swappingBandIndex = bandIndex+1;
        reorderUp = NO;
    }
    
    // Check for reordering
    if (swappingLab &&
        ((reorderUp && (swappingLab.center.y > draggingLabel.center.y || swappingLab.center.x > draggingLabel.center.x)) 
         ||
        (!reorderUp && (swappingLab.center.y < draggingLabel.center.y || swappingLab.center.x < draggingLabel.center.x))))
    {
        if (draggingLabelType == PANEL)
        {
            [self reorderPanel:panelIndex withNewIndex:swappingPanelIndex];
            [_dataDelegate swapPanel:panelIndex withPanel:swappingPanelIndex];
        }
        else if (draggingLabelType == STACK)
        {
            [self swapStackLabels:stackIndex and:swappingStackIndex];
            for (PanelZoomView *p in _panelZoomViews)
                [p.panelDrawView reorderStack:stackIndex withNewIndex:swappingStackIndex];
            // Inform data delegate that reordering is needed
            [_dataDelegate swapStack:stackIndex withStack:swappingStackIndex];
        }
        else if (draggingLabelType == BAND)
        {
            [self swapAllBandLabels:bandIndex and:swappingBandIndex skippingStack:stackIndex areBothDragging:YES];
            for (PanelZoomView *p in _panelZoomViews)
                [p.panelDrawView reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:swappingBandIndex];
            // Inform data delegate that reordering is needed
            [_dataDelegate swapBand:bandIndex withBand:swappingBandIndex];
        }
        
        // Set new indices by replacing the dragging array
        NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
        NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
        NSMutableArray *mutaSwappingDragArr = [swappingDragArr mutableCopy];
        if (draggingLabelType == PANEL)
        {
            [mutaDraggingArr replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:swappingPanelIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:panelIndex]];
        }
        else if (draggingLabelType == STACK)
        {
            [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:swappingStackIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:stackIndex]];            
        }
        else if (draggingLabelType == BAND)
        {
            [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:swappingBandIndex]];
            [mutaSwappingDragArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:bandIndex]];
        }
        
        [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaSwappingDragArr];
        [mutaDraggingLabels replaceObjectAtIndex:swappingLabelIndex withObject:(NSArray *)mutaDraggingArr];
        _draggingLabels = (NSArray *)mutaDraggingLabels;
    }
    
    //  Handle swapping with non-dragging label
   else   
    {
        QueryData *data = [_dataDelegate delegateRequestsQueryData];
        float stackHeight = (data.bandNum-1.0f) * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_BAND_HEIGHT + ZOOMED_TIMELINE_HEIGHT;
        int newIndex;
        if (draggingLabelType == PANEL)
        {
            float normalX;
            if (isPortrait) normalX = point.x;
            else            
            {
                if (isLeftHanded)   normalX = point.x - SIDE_LABEL_SPACING;
                else                normalX = point.x - (1.0f/4.0f * (768.0f - BAND_WIDTH_P));
            }
            newIndex = normalX / ZOOMED_BAND_WIDTH;
        }
        else if (draggingLabelType == STACK)
        {
            float normalY;
            if (isPortrait) normalY = point.y;
            else            normalY = point.y - TOP_LABEL_SPACING;
            newIndex = normalY / stackHeight;
        }
        else if (draggingLabelType == BAND)
        {
            float normalY;
            if (isPortrait) normalY = point.y - (stackHeight * stackIndex) - ZOOMED_TIMELINE_HEIGHT;
            else            normalY = point.y - (stackHeight * stackIndex) - ZOOMED_TIMELINE_HEIGHT - TOP_LABEL_SPACING;
            newIndex = normalY / (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING);            
            NSLog(@"Newindex: %d, normalY: %f", newIndex, normalY);
        }
        
        // Make sure new index is not currently being dragged
        BOOL beingDragged = NO;
        for (NSArray *a in _draggingLabels)
        {
            if ((draggingLabelType == PANEL && ([[a objectAtIndex:4] intValue] == newIndex)) ||
                (draggingLabelType == STACK && ([[a objectAtIndex:3] intValue] == newIndex)) ||
                (draggingLabelType == BAND && ([[a objectAtIndex:2] intValue] == newIndex)))
            {
                beingDragged = YES;
                break;
            }
        }
        
        // Reorder
        if (draggingLabelType == PANEL && (newIndex != panelIndex) && (newIndex >= 0) && !beingDragged)
        {
            if ([self reorderPanel:panelIndex withNewIndex:newIndex])
            {
                [self swapPanelLabels:panelIndex and:newIndex];
                // Inform data delegate
                [_dataDelegate swapPanel:panelIndex withPanel:newIndex];
                
                // Set new index in dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:4 withObject:[NSNumber numberWithInt:newIndex]];
                
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
                // Inform data delegate that reordering is needed
                [_dataDelegate swapStack:stackIndex withStack:newIndex];
                
                // Set new index in dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:3 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
        else if (draggingLabelType == BAND && (newIndex != bandIndex) && (newIndex >= 0) && !beingDragged)
        {                
            if ([_drawDelegate reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:newIndex])
            {
                for (int i = 1; i < [_panelZoomViews count]; i++)
                {
                    PanelZoomView *p = [_panelZoomViews objectAtIndex:i];
                    [p.panelDrawView reorderBandsAroundBand:bandIndex inStack:stackIndex withNewIndex:newIndex];
                }
                [self swapAllBandLabels:bandIndex and:newIndex skippingStack:stackIndex areBothDragging:NO];
                // Inform data delegate that reordering is needed
                [_dataDelegate swapBand:bandIndex withBand:newIndex];
                
                // Set new index by replacing the dragging array
                NSMutableArray *mutaDraggingLabels = [_draggingLabels mutableCopy];
                NSMutableArray *mutaDraggingArr = [draggingArr mutableCopy];
                [mutaDraggingArr replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:newIndex]];
                
                [mutaDraggingLabels replaceObjectAtIndex:draggingLabelIndex withObject:(NSArray *)mutaDraggingArr];
                _draggingLabels = (NSArray *)mutaDraggingLabels;
            }
        }
    }
    
//    [CATransaction commit];
}

/**
 *  Handle the resulting location of the dragged DraggingLabel.
 *
 *  gestureRecognizer is the UILongPressGestureRecognizer responsible for drag-and-drop functionality.
 */
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{    
    DraggableLabel *draggingLabel = (DraggableLabel *)[gestureRecognizer view];
    NSArray *draggingArr;
    for (NSArray *a in _draggingLabels)
    {
        if ([a objectAtIndex:0] == draggingLabel)
        {
            draggingArr = a;
            break;
        }
    }
    if (!draggingArr) return;
    
    int panelIndex = [[draggingArr objectAtIndex:4] intValue];
    int stackIndex = [[draggingArr objectAtIndex:3] intValue];
    int bandIndex = [[draggingArr objectAtIndex:2] intValue];
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_BAND_HEIGHT + ZOOMED_TIMELINE_HEIGHT;
    
    // Find the type of layer we're dragging
    enum UI_OBJECT draggingLabelType = -1;
    if (bandIndex == -1 && stackIndex == -1)
    {
        draggingLabelType = PANEL;
    }
    else if (bandIndex == -1)
    {
        draggingLabelType = STACK;
    }
    else
    {
        draggingLabelType = BAND;
    }
    
    // Set new position for dropped layer based on its index
    CGRect labelF = draggingLabel.frame;
    if (draggingLabelType == PANEL)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_panelFontSize]];
         // Movel label to rest
        if (isLeftHanded)   labelF.origin.x = SIDE_LABEL_SPACING + panelIndex * ZOOMED_BAND_WIDTH;
        else                labelF.origin.x = (1.0f/4.0f * (768.0f - BAND_WIDTH_P)) + panelIndex * ZOOMED_BAND_WIDTH;
    }
    else if (draggingLabelType == STACK)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize]];
        // Move label to rest
        float stackY;
        if (isPortrait) stackY = stackIndex * stackHeight;
        else            stackY = stackIndex * stackHeight + TOP_LABEL_SPACING;
        labelF.origin.y = stackY;
    }
    else if (draggingLabelType == BAND)
    {
        [draggingLabel setFont:[UIFont fontWithName:@"Helvetica" size:_bandFontSize]];
        // Move label to rest
        float stackY;
        if (isPortrait) stackY = stackIndex * stackHeight;
        else            stackY = stackIndex * stackHeight + TOP_LABEL_SPACING;
        float bandY = bandIndex * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_TIMELINE_HEIGHT + stackY;
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
#pragma mark Panel management

- (BOOL)reorderPanel:(int)panelIndex withNewIndex:(int)index
{
    if (panelIndex >= [_panelZoomViews count]) return NO;
    if (index >= [_panelZoomViews count]) return NO;
    
    PanelZoomView *p1 = [_panelZoomViews objectAtIndex:panelIndex];
    PanelZoomView *p2 = [_panelZoomViews objectAtIndex:index];
    CGRect p1Frame = p1.frame;
    CGRect p2Frame = p2.frame;
    
    [PanelZoomView beginAnimations:nil context:nil];
//    [PanelZoomView setAnimationDuration:0.2f];
//    [PanelZoomView setAnimationDelay:0.0f];
//    [PanelZoomView setAnimationCurve:UIViewAnimationCurveLinear];
    p1.frame = p2Frame;
    p2.frame = p1Frame;
    // Check to show/hide primary panel view
    if (isPortrait && panelIndex == 0)
    {
        [self addSubview:p2];
        [p1 removeFromSuperview];
    }
    if (isPortrait && index == 0)
    {
        [self addSubview:p1];
        [p2 removeFromSuperview];
    }
    [PanelZoomView commitAnimations];
    
    CGRect p1Original = p1.originalFrame;
    p1.originalFrame = p2.originalFrame;
    p2.originalFrame = p1Original;
    
    // Reorder panels in their array
    NSMutableArray *mutaZoomViews = [_panelZoomViews mutableCopy];
    [mutaZoomViews replaceObjectAtIndex:panelIndex withObject:p2];
    [mutaZoomViews replaceObjectAtIndex:index withObject:p1];
    _panelZoomViews = (NSArray *)mutaZoomViews;
    
    // Inform their drawing views of their new index
    p1.panelDrawView.currentPanel = index;
    p2.panelDrawView.currentPanel = panelIndex;    
    
    return YES;
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
    ZOOMED_BAND_WIDTH = BAND_WIDTH * scrollView.zoomScale;
    ZOOMED_BAND_HEIGHT = BAND_HEIGHT * scrollView.zoomScale;
    ZOOMED_BAND_SPACING = BAND_SPACING * scrollView.zoomScale;
    ZOOMED_TIMELINE_HEIGHT = TIMELINE_HEIGHT * scrollView.zoomScale;
    
    // Resize panels
    for (PanelZoomView *p in _panelZoomViews)
    {
        [p zoomToScale:scrollView.zoomScale];
    }
    
    // Resize label frames
    CGRect newLabelF = _sideLabelView.frame;
    newLabelF.size.height = _queryContentView.frame.size.height;// + 1024.0f;
    _sideLabelView.frame = newLabelF;
    newLabelF = _topLabelView.frame;
/*    if (isLeftHanded) */  newLabelF.size.width = /*SIDE_LABEL_SPACING +*/ ZOOMED_BAND_WIDTH * data.panelNum;
//    else                newLabelF.size.width = (1.0f/4.0f * (768.0f - BAND_WIDTH_P)) + ZOOMED_BAND_WIDTH * data.panelNum;
    _topLabelView.frame = newLabelF;
    
    _stackFontSize = (ZOOMED_TIMELINE_HEIGHT + 1.0f < 20.0f ? ZOOMED_TIMELINE_HEIGHT + 1.0f : 20.0f);
    _bandFontSize = (ZOOMED_BAND_HEIGHT + 1.0f < 16.0f ? ZOOMED_BAND_HEIGHT + 1.0f : 16.0f);
    
    // Resize panel labels
    for (int i = 0; i < data.panelNum; i++)
    {
        DraggableLabel *panelLabel = [_panelLabelArray objectAtIndex:i];
        CGRect labelF = CGRectMake(/*(1.0f/4.0f * (768.0f - BAND_WIDTH_P)) +*/ (ZOOMED_BAND_WIDTH * i), 
                                   0.0f, 
                                   ZOOMED_BAND_WIDTH, 
                                   50.0f);
//        if (isLeftHanded)   labelF.origin.x = SIDE_LABEL_SPACING + (ZOOMED_BAND_WIDTH * i);
        panelLabel.frame = labelF;
    }
    
    // Resize stack and band labels
    float stackHeight = (data.bandNum-1.0f) * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_BAND_HEIGHT + ZOOMED_TIMELINE_HEIGHT;
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY;
        if (isPortrait) stackY = stackHeight * i;// + 1024.0f;
        else            stackY = TOP_LABEL_SPACING + stackHeight * i;// + 1024.0f;
		CGRect labelF = CGRectMake(16.0f, stackY, 128.0f, ZOOMED_TIMELINE_HEIGHT);
		DraggableLabel *stackL = [_stackLabelArray objectAtIndex:i];
        stackL.frame = labelF;
        stackL.font = [UIFont fontWithName:@"Helvetica-Bold" size:_stackFontSize];
		
        NSArray *currentBandLabels = [_bandLabelArray objectAtIndex:i];
		for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (ZOOMED_BAND_HEIGHT + ZOOMED_BAND_SPACING) + ZOOMED_TIMELINE_HEIGHT + stackY;
            labelF = CGRectMake(32.0f, bandY, 128.0f, ZOOMED_BAND_HEIGHT);
			DraggableLabel *bandL = [currentBandLabels objectAtIndex:j];
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
    
    CGRect newFrame = _topLabelView.frame;
    newFrame.origin.y = offset.y;
    if(!isPortrait) _topLabelView.frame = newFrame;
    [self bringSubviewToFront:_topLabelView];
    
    newFrame = _sideLabelView.frame;
    if (!isPortrait)
    {
        if (isLeftHanded)
        {
            newFrame.origin.x = offset.x;
        }
        else
        {
            newFrame.origin.x = offset.x + 1024.0f - SIDE_LABEL_SPACING;
        }
    }
    
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
