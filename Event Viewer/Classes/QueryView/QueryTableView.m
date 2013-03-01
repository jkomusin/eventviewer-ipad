
#import "QueryTableView.h"

// Global UI layout parameters
OBJC_EXPORT float SIDE_LABEL_SPACING;


@implementation QueryTableView

@synthesize tableView = _tableView;
@synthesize titleView = _titleView;

/**
 *	Create a UITableView offset to the right, and a UILabel offset to the left
 */
- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.75f];
		self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
		self.layer.borderWidth = 1.0f;
		self.layer.masksToBounds = YES;
		self.layer.cornerRadius = 5.0f;
		
		CGRect tFrame = CGRectMake(SIDE_LABEL_SPACING,
									7.5f,
									frame.size.width - 10.0f - SIDE_LABEL_SPACING,
									frame.size.height - 15.0f);
		_tableView = [[UITableView alloc] initWithFrame:tFrame];
		_tableView.allowsSelection = NO;
		_tableView.layer.cornerRadius = 5.0f;
		_tableView.showsVerticalScrollIndicator = YES;
		[self addSubview:_tableView];
		
		CGRect lFrame = CGRectMake(0.0f, 
								   0.0f, 
								   SIDE_LABEL_SPACING - 20.0f, 
								   frame.size.height);
		_titleView = [[UILabel alloc] initWithFrame:lFrame];
		_titleView.font = [UIFont fontWithName:@"Helvetica-Bold" size:32.0f];
		_titleView.textColor = [UIColor whiteColor];
		_titleView.textAlignment = UITextAlignmentRight;
		_titleView.backgroundColor = [UIColor clearColor];
		[self addSubview:_titleView];
	}
	
	return self;
}

@end
