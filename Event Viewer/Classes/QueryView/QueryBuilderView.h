//
//  QueryView.h
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrimaryViewController.h"

@class Constraint;

/**
 *  Delegate protocol to provide notifications of query modifications.
 */
@protocol QueryDelegate
@required
- (void)queryDidChange;
- (void)queryDidSwapLabelsOfUIType:(enum UI_OBJECT)type withIndices:(NSInteger)i and:(NSInteger)j; 

@end


/**
 *  View handling the creation of a query by the user.
 */
@interface QueryBuilderView : UIView <QueryDelegate, UITableViewDelegate>
{
}

@property (nonatomic, strong) PrimaryViewController *primaryController;
@property (nonatomic, strong) UITableView *bandTable;     //
@property (nonatomic, strong) UITableView *stackTable;    // The group of tables containing the seleced constraints
@property (nonatomic, strong) UITableView *panelTable;    //

@property (nonatomic, assign) BOOL queryHasChanged;

- (void)initQueryTablesWithDataSource:(id<UITableViewDataSource>)source;

- (void)droppedConstraint:(Constraint *)constraint withGesture:(UIGestureRecognizer *)recognizer;

- (void)editButtonPressed;

@end
