//
//  QueryTableView.h
//  Event Viewer
//
//  Created by Home on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/**
 *	Overridden UIView to display an outline containing a title label next to a UITableView
 */
@interface QueryTableView : UIView
{
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UILabel *titleView;

@end
