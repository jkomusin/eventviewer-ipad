//
//  QueryView.m
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "QueryBuilderView.h"
#import "MGSplitViewController.h"
#import "PrimaryViewController.h"
#import "QueryTableView.h"
#import "Constraint.h"
#import "Query.h"

// Global UI layout parameters
OBJC_EXPORT float SIDE_LABEL_SPACING;


@interface QueryBuilderView ()
- (void)setTableToRest:(QueryTableView *)table;
- (void)handleDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

@end


@implementation QueryBuilderView
{
	BOOL _isDragging;	// Is the user currently dragging a bin?
	BOOL _isEditing;		// Is the user currently editing bins?
}

@synthesize primaryController = _primaryController;
@synthesize panelTable = _panelTable;
@synthesize stackTable = _stackTable;
@synthesize bandTable = _bandTable;

@synthesize queryHasChanged = _queryHasChanged;

// UI Layout constants
float TABLE_HEIGHT = ((768.0f - 44.0f) - 65.0f - 45.0f) / 3.0f;
float TABLE_WIDTH = (1024.0f - MG_DEFAULT_SPLIT_POSITION - MG_DEFAULT_SPLIT_WIDTH) - 20.0f;


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
		
        _queryHasChanged = NO;
		_isDragging = NO;
		_isEditing = NO;
    }
    
    return self;
}
    
/**
 *  Initialize query tables to their starting states, resetting the query builder.
 *  In placing the tables, we assume that the query builder view has been sized to take into account the nav bar and query table, etc.
 *  We also assume that the orientation is landscape.
 */
- (void)initQueryTablesWithDataSource:(Query *)source
{
    if (_bandTable) [_bandTable removeFromSuperview];
    if (_stackTable) [_stackTable removeFromSuperview];
    if (_panelTable) [_panelTable removeFromSuperview];
    
    CGRect bandFrame = CGRectMake(10.0f,
                                  80.0f,
                                  TABLE_WIDTH,
                                  TABLE_HEIGHT);
	_bandTable = [[QueryTableView alloc] initWithFrame:bandFrame];
	_bandTable.titleView.text = @"Bands";
	_bandTable.tableView.dataSource = source;
	_bandTable.tableView.tag = UIObjectBand;
	UILongPressGestureRecognizer* bDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
	bDragGesture.delegate = self;
	bDragGesture.cancelsTouchesInView = NO;
	[bDragGesture setNumberOfTouchesRequired:1];
	[bDragGesture setMinimumPressDuration:0.1f];
	[_bandTable addGestureRecognizer:bDragGesture];
	[_bandTable setUserInteractionEnabled:YES];
	[self addSubview:_bandTable];
	
	CGRect stackFrame = CGRectMake(10.0f, 
								   80.0f + TABLE_HEIGHT + 5.0f, 
								   TABLE_WIDTH, 
								   TABLE_HEIGHT);
	_stackTable = [[QueryTableView alloc] initWithFrame:stackFrame];
	_stackTable.titleView.text = @"Stacks";
	_stackTable.tableView.dataSource = source;
	_stackTable.tableView.tag = UIObjectStack;
	UILongPressGestureRecognizer* sDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
	sDragGesture.delegate = self;
	sDragGesture.cancelsTouchesInView = NO;
	[sDragGesture setNumberOfTouchesRequired:1];
	[sDragGesture setMinimumPressDuration:0.1f];
	[_stackTable addGestureRecognizer:sDragGesture];
	[_stackTable setUserInteractionEnabled:YES];
	[self addSubview:_stackTable];
	
	CGRect panelFrame = CGRectMake(10.0f, 
								   80.0f + 2.0f * (TABLE_HEIGHT + 5.0f), 
								   TABLE_WIDTH, 
								   TABLE_HEIGHT);
	_panelTable = [[QueryTableView alloc] initWithFrame:panelFrame];
	_panelTable.titleView.text = @"Panels";
	_panelTable.tableView.dataSource = source;
	_panelTable.tableView.tag = UIObjectPanel;
	UILongPressGestureRecognizer* pDragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
	pDragGesture.delegate = self;
	pDragGesture.cancelsTouchesInView = NO;
	[pDragGesture setNumberOfTouchesRequired:1];
	[pDragGesture setMinimumPressDuration:0.1f];
	[_panelTable addGestureRecognizer:pDragGesture];
	[_panelTable setUserInteractionEnabled:YES];
	[self addSubview:_panelTable];
	
	source.queryDelegate = self;
	
	[self editButtonPressed];
}


#pragma mark -
#pragma mark Drop management

- (void)droppedConstraint:(Constraint *)constraint withGesture:(UIGestureRecognizer *)recognizer
{
	for (UIView *v in [self subviews])
	{
		if ([v isKindOfClass:[QueryTableView class]] && [v pointInside:[recognizer locationInView:v] withEvent:nil])
		{
			QueryTableView *table = (QueryTableView *)v;
			Query *currentQuery = (Query *)table.tableView.dataSource;
			[currentQuery addConstraint:constraint toArray:table.tableView.tag];	// tag indicates type
			
			[table.tableView reloadData];
			[self queryDidChange];
		}
	}
}

- (void)editButtonPressed
{
	for (UIView *v in [self subviews])
	{
		if ([v isKindOfClass:[QueryTableView class]])
		{
			QueryTableView *table = (QueryTableView *)v;
			[table.tableView setEditing:(!_isEditing)];
			for (UITableViewCell *cell in table.tableView.visibleCells)
			{
				cell.showsReorderControl = (!_isEditing);
			}
		}
	}
	
	_isEditing = (!_isEditing);
}


#pragma mark -
#pragma mark Drag-and-drop handling for bins

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([_panelTable.tableView pointInside:[touch locationInView:_panelTable.tableView] withEvent:nil] ||
		[_stackTable.tableView pointInside:[touch locationInView:_stackTable.tableView] withEvent:nil] ||
		[_bandTable.tableView pointInside:[touch locationInView:_bandTable.tableView] withEvent:nil]
		)
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

/**
 *	Entry point for dragging-and-dropping of bin label
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

- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (_isDragging)	
	{
		gestureRecognizer.enabled = NO;	// toggling this will cancel the gesture
		gestureRecognizer.enabled = YES;
		return;
	}
	else
	{
		_isDragging = YES;
	}
	
	QueryTableView *draggingTable = (QueryTableView *)gestureRecognizer.view;
	draggingTable.alpha = 0.75f;
	[self bringSubviewToFront:draggingTable];
}

- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer
{
	QueryTableView *draggingTable = (QueryTableView *)gestureRecognizer.view;
	CGPoint p = [gestureRecognizer locationInView:self];
	p.x = draggingTable.center.x;
	[draggingTable setCenter:p];
}

- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer
{
	QueryTableView *draggingTable = (QueryTableView *)gestureRecognizer.view;
	
	for (UIView *v in [self subviews])
	{
		if ([v isKindOfClass:[QueryTableView class]] && [v pointInside:[gestureRecognizer locationInView:v] withEvent:nil] && v != draggingTable)
		{
			QueryTableView *table = (QueryTableView *)v;
			
			// Swap their types
			enum UI_OBJECT temp = table.tableView.tag;
			table.tableView.tag = draggingTable.tableView.tag;
			draggingTable.tableView.tag = temp;
			
			// Swap their labels
			NSString *tempString = table.titleView.text;
			table.titleView.text = draggingTable.titleView.text;
			draggingTable.titleView.text = tempString;
			
			// Notify data model
			Query *q = (Query *)draggingTable.tableView.dataSource;
			[q swapBinData:draggingTable.tableView.tag withBin:table.tableView.tag];
			
			[self setTableToRest:table];

			// Notfy content controller
			[_primaryController reConfigureCanvas];
		}
	}
	
	// Set tables to their resting positions
	[self setTableToRest:draggingTable];
	draggingTable.alpha = 1.0f;
	_isDragging = NO;
}

/**
 *	Sets a QueryTableView's frame to it's proper location given its table's tag
 */
- (void)setTableToRest:(QueryTableView *)table
{
	CGRect frame = CGRectNull;
	if (table.tableView.tag == UIObjectBand)
	{
		frame = CGRectMake(10.0f,
						   80.0f,
						   TABLE_WIDTH,
						   TABLE_HEIGHT);
	}
	else if (table.tableView.tag == UIObjectStack)
	{
		frame = CGRectMake(10.0f, 
						   80.0f + TABLE_HEIGHT + 5.0f, 
						   TABLE_WIDTH, 
						   TABLE_HEIGHT);
	}
	else if (table.tableView.tag == UIObjectPanel)
	{
		frame = CGRectMake(10.0f, 
						   80.0f + 2.0f * (TABLE_HEIGHT + 5.0f), 
						   TABLE_WIDTH, 
						   TABLE_HEIGHT);
	}
	else
	{
		NSLog(@"ERROR: Invalid table tag: %d", table.tableView.tag);
	}

	[QueryTableView beginAnimations:nil context:nil];
	table.frame = frame;
	[QueryTableView commitAnimations];
}


#pragma mark -
#pragma mark Query delegation

/**
 *	Called whenever the query has been modified in such a way that requerying is necessary.
 *	Primarily for adding/deleting constraints
 */
- (void)queryDidChange
{
	_queryHasChanged = YES;
}

/**
 *	Called upon reordering of rows in the query tables
 */
- (void)queryDidSwapLabelsOfUIType:(enum UI_OBJECT)type withIndices:(NSInteger)i and:(NSInteger)j
{
	if (type == UIObjectPanel)
	{
		// Swap data model
		[_primaryController swapPanelData:i withPanel:j];
		// Swap visual respresentation
		[_primaryController swapPanelLayer:i withPanel:j];
	}
	else if (type == UIObjectStack)
	{
		// Swap data model
		[_primaryController swapStackData:i withStack:j];
		// Swap visual representation
		[_primaryController swapStackLayer:i withStack:j];
	}
	else if (type == UIObjectBand)
	{
		// Swap data model
		[_primaryController swapBandData:i withBand:j];
		// Swap visual representation
		[_primaryController swapBandLayer:i withBand:j];
	}
	else
	{
		NSLog(@"ERROR: Problem in Query builder view, attempting to swap with unknwon type: %d", type);
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
