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
@class QueryTableView;

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
@interface QueryBuilderView : UIView <QueryDelegate, UITableViewDelegate, UIGestureRecognizerDelegate>
{
}

@property (nonatomic, strong) PrimaryViewController *primaryController;
@property (nonatomic, strong) QueryTableView *bandTable;     //
@property (nonatomic, strong) QueryTableView *stackTable;    // The group of tables containing the seleced constraints
@property (nonatomic, strong) QueryTableView *panelTable;    //

@property (nonatomic, assign) BOOL queryHasChanged;

- (void)initQueryTablesWithDataSource:(id<UITableViewDataSource>)source;

- (void)droppedConstraint:(Constraint *)constraint withGesture:(UIGestureRecognizer *)recognizer;

- (void)editButtonPressed;

@end
