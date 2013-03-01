
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
