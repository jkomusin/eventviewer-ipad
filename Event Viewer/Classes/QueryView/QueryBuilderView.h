//
//  QueryView.h
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Constraint;

/**
 *  View handling the creation of a query by the user.
 */
@interface QueryBuilderView : UIView
{
    
}

@property (nonatomic, assign) BOOL queryHasChanged;

- (void)initQueryTablesWithDataSource:(id<UITableViewDataSource>)source;

- (void)droppedConstraint:(Constraint *)constraint withGesture:(UIGestureRecognizer *)recognizer;

@end
