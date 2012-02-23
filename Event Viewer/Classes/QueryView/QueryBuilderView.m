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
#import "Constraint.h"
#import "Query.h"

// Global UI layout parameters
OBJC_EXPORT float SIDE_LABEL_SPACING;


@implementation QueryBuilderView
{
}

@synthesize primaryController = _primaryController;
@synthesize panelTable = _panelTable;
@synthesize stackTable = _stackTable;
@synthesize bandTable = _bandTable;

@synthesize queryHasChanged = _queryHasChanged;


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        
        // Set up labels
        float tableHeight = (self.frame.size.height - 65.0f - 5.0f - 60.0f) / 3.0f; // The 4.0 ensures an integer result and a tiny bit more space at the bottom
        
        CGRect bandF = CGRectMake(20.0f, 
                                  80.0f, 
                                  SIDE_LABEL_SPACING - 40.0f, 
                                  tableHeight);
        UILabel *bandL = [[UILabel alloc] initWithFrame:bandF];
        [bandL setTextAlignment:UITextAlignmentRight];
        [bandL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:32.0f]];
        [bandL setBackgroundColor:[UIColor clearColor]];
        [bandL setTextColor:[UIColor whiteColor]];
        [bandL setText:@"Bands"];
        [self addSubview:bandL];
        
        CGRect stackF = CGRectMake(20.0f, 
                                   80.0f + tableHeight + 15.0f, 
                                   SIDE_LABEL_SPACING - 40.0f, 
                                   tableHeight);
        UILabel *stackL = [[UILabel alloc] initWithFrame:stackF];
        [stackL setTextAlignment:UITextAlignmentRight];
        [stackL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:32.0f]];
        [stackL setBackgroundColor:[UIColor clearColor]];
        [stackL setTextColor:[UIColor whiteColor]];
        [stackL setText:@"Stacks"];
        [self addSubview:stackL];
        
        CGRect panelF = CGRectMake(20.0f, 
                                   80.0f + 2.0f * (tableHeight + 15.0f), 
                                   SIDE_LABEL_SPACING - 40.0f, 
                                   tableHeight);
        UILabel *panelL = [[UILabel alloc] initWithFrame:panelF];
        [panelL setTextAlignment:UITextAlignmentRight];
        [panelL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:32.0f]];
        [panelL setBackgroundColor:[UIColor clearColor]];
        [panelL setTextColor:[UIColor whiteColor]];
        [panelL setText:@"Panels"];
        [self addSubview:panelL];
		
        _queryHasChanged = NO;
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
    
    float tableHeight = (self.frame.size.height - 65.0f - 5.0f - 60.0f) / 3.0f;
    float tableWidth = self.frame.size.width - SIDE_LABEL_SPACING - 20.0f;
    
    CGRect bandFrame = CGRectMake(SIDE_LABEL_SPACING,
                                  80.0f,
                                  tableWidth,
                                  tableHeight);
    UITableView *newBands = [[UITableView alloc] initWithFrame:bandFrame style:UITableViewStylePlain];
    newBands.tag = UIObjectBand;
    newBands.dataSource = source;
	newBands.allowsSelection = NO;
	newBands.layer.cornerRadius = 5.0f;
	newBands.showsVerticalScrollIndicator = YES;
    [self addSubview:newBands];
    _bandTable = newBands;
    
    CGRect stackFrame = CGRectMake(SIDE_LABEL_SPACING, 
                                   80.0f + tableHeight + 15.0f, 
                                   tableWidth, 
                                   tableHeight);
    UITableView *newStacks = [[UITableView alloc] initWithFrame:stackFrame style:UITableViewStylePlain];
    newStacks.tag = UIObjectStack;
    newStacks.dataSource = source;
	newStacks.allowsSelection = NO;
	newStacks.layer.cornerRadius = 5.0f;
	newStacks.showsVerticalScrollIndicator = YES;
    [self addSubview:newStacks];
    _stackTable = newStacks;
    
    CGRect panelFrame = CGRectMake(SIDE_LABEL_SPACING, 
                                   80.0f + 2.0F * (tableHeight + 15.0f), 
                                   tableWidth, 
                                   tableHeight);
    UITableView *newPanels = [[UITableView alloc] initWithFrame:panelFrame style:UITableViewStylePlain];
    newPanels.tag = UIObjectPanel;
    newPanels.dataSource = source;
	newPanels.allowsSelection = NO;
	newPanels.layer.cornerRadius = 5.0f;
	newPanels.showsVerticalScrollIndicator = YES;
    [self addSubview:newPanels];
    _panelTable = newPanels;
	
	source.queryDelegate = self;
}


#pragma mark -
#pragma mark Drop management

- (void)droppedConstraint:(Constraint *)constraint withGesture:(UIGestureRecognizer *)recognizer
{
    if ([_bandTable pointInside:[recognizer locationInView:_bandTable] withEvent:nil])
    {
        Query *currentQuery = (Query *)_bandTable.dataSource;
        [currentQuery addConstraint:constraint toArray:UIObjectBand];
        
        [_bandTable reloadData];
        [self queryDidChange];
    }
    else if ([_stackTable pointInside:[recognizer locationInView:_stackTable] withEvent:nil])
    {
        Query *currentQuery = (Query *)_stackTable.dataSource;
        [currentQuery addConstraint:constraint toArray:UIObjectStack];
        
        [_stackTable reloadData];
        [self queryDidChange];
    }
    else if ([_panelTable pointInside:[recognizer locationInView:_panelTable] withEvent:nil])
    {
        Query *currentQuery = (Query *)_panelTable.dataSource;
        [currentQuery addConstraint:constraint toArray:UIObjectPanel];
        
        [_panelTable reloadData];
        [self queryDidChange];
    }
}


- (void)editButtonPressed
{
	if (_bandTable.editing || _stackTable.editing || _panelTable.editing)
	{
		[_bandTable setEditing:NO];
		for (UITableViewCell *cell in _bandTable.visibleCells)
		{
			cell.showsReorderControl = NO;
		}
		
		[_stackTable setEditing:NO];
		for (UITableViewCell *cell in _stackTable.visibleCells)
		{
			cell.showsReorderControl = NO;
		}
		
		[_panelTable setEditing:NO];
		for (UITableViewCell *cell in _panelTable.visibleCells)
		{
			cell.showsReorderControl = NO;
		}

	}
	else
	{
		[_bandTable setEditing:YES];
		for (UITableViewCell *cell in _bandTable.visibleCells)
		{
			cell.showsReorderControl = YES;
		}
		
		[_stackTable setEditing:YES];
		for (UITableViewCell *cell in _stackTable.visibleCells)
		{
			cell.showsReorderControl = YES;
		}
		
		[_panelTable setEditing:YES];
		for (UITableViewCell *cell in _panelTable.visibleCells)
		{
			cell.showsReorderControl = YES;
		}
	}
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
