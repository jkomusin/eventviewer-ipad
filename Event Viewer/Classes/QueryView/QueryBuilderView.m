//
//  QueryView.m
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QueryBuilderView.h"
#import "MGSplitViewController.h"
#import "PrimaryViewController.h"
#import "Constraint.h"

// Global UI layout parameters
OBJC_EXPORT float SIDE_LABEL_SPACING;


@implementation QueryBuilderView
{
    UITableView *_bandTable;     //
    UITableView *_stackTable;    // The group of tables containing the seleced constraints
    UITableView *_panelTable;    //
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Set up labels
        float tableHeight = (self.frame.size.height - 4.0f - 60.0f) / 3.0f; // The 4.0 ensures an integer result and a tiny bit more space at the bottom
        
        CGRect bandF = CGRectMake(20.0f, 
                                  15.0f, 
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
                                   15.0f + tableHeight + 15.0f, 
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
                                   15.0f + 2.0f * (tableHeight + 15.0f), 
                                   SIDE_LABEL_SPACING - 40.0f, 
                                   tableHeight);
        UILabel *panelL = [[UILabel alloc] initWithFrame:panelF];
        [panelL setTextAlignment:UITextAlignmentRight];
        [panelL setFont:[UIFont fontWithName:@"Helvetica-Bold" size:32.0f]];
        [panelL setBackgroundColor:[UIColor clearColor]];
        [panelL setTextColor:[UIColor whiteColor]];
        [panelL setText:@"Panels"];
        [self addSubview:panelL];
    }
    
    return self;
}
    
/**
 *  Initialize query tables to their starting states, resetting the query builder.
 *  In placing the tables, we assume that the query builder view has been sized to take into account the nav bar and query table, etc.
 *  We also assume that the orientation is landscape.
 */
- (void)initQueryTablesWithDataSource:(id<UITableViewDataSource>)source
{
    if (_bandTable) [_bandTable removeFromSuperview];
    if (_stackTable) [_stackTable removeFromSuperview];
    if (_panelTable) [_panelTable removeFromSuperview];
    
    float tableHeight = (self.frame.size.height - 4.0f - 60.0f) / 3.0f; // The 4.0 ensures an integer result and a tiny bit more space at the bottom
    float tableWidth = self.frame.size.width - SIDE_LABEL_SPACING - 20.0f;
    
    CGRect bandFrame = CGRectMake(SIDE_LABEL_SPACING,
                                  15.0f,
                                  tableWidth,
                                  tableHeight);
    UITableView *newBands = [[UITableView alloc] initWithFrame:bandFrame style:UITableViewStylePlain];
    newBands.tag = BAND;
    newBands.dataSource = source;
    [self addSubview:newBands];
    _bandTable = newBands;
    
    CGRect stackFrame = CGRectMake(SIDE_LABEL_SPACING, 
                                   15.0f + tableHeight + 15.0f, 
                                   tableWidth, 
                                   tableHeight);
    UITableView *newStacks = [[UITableView alloc] initWithFrame:stackFrame style:UITableViewStylePlain];
    newStacks.tag = STACK;
    newStacks.dataSource = source;
    [self addSubview:newStacks];
    _stackTable = newStacks;
    
    CGRect panelFrame = CGRectMake(SIDE_LABEL_SPACING, 
                                   15.0f + 2.0F * (tableHeight + 15.0f), 
                                   tableWidth, 
                                   tableHeight);
    UITableView *newPanels = [[UITableView alloc] initWithFrame:panelFrame style:UITableViewStylePlain];
    newPanels.tag = PANEL;
    newPanels.dataSource = source;
    [self addSubview:newPanels];
    _panelTable = newPanels;
}


#pragma mark -
#pragma mark Drop management

- (void)droppedConstraint:(Constraint *)constraint atPoint:(CGPoint)point
{
    if ([_bandTable pointInside:point withEvent:nil])
    {
        NSLog(@"Constraint with name '%@' is inside Bands table!", constraint.name);
    }
    else if ([_stackTable pointInside:point withEvent:nil])
    {
        NSLog(@"Constraint with name '%@' is inside Stacks table!", constraint.name);        
    }
    else if ([_panelTable pointInside:point withEvent:nil])
    {
        NSLog(@"Constraint with name '%@' is inside Panels table!", constraint.name);        
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
