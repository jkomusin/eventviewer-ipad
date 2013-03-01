
#import "EventInfo.h"
#import "Event.h"

@implementation EventInfo


- (id)initWithEventArray:(NSArray *)eventArr
{
    if ((self = [super init]))
    {
		NSDateFormatter *dateMaker = [[NSDateFormatter alloc] init];
		[dateMaker setDateFormat:@"yyyy-MM-dd HH:mm"];
		
        CGRect frame = CGRectMake(0.0f, 0.0f, 200.0f, [eventArr count] * 50.0f);
        self.contentSizeForViewInPopover = CGSizeMake(200.0f, [eventArr count] * 50.0f);
        UIView *v = [[UIView alloc] initWithFrame:frame];
        v.backgroundColor = [UIColor whiteColor];
        for (int i = 0; i < [eventArr count]; i++)
        {
            Event *e = [eventArr objectAtIndex:i];
            CGRect startFrame = CGRectMake(0.0f, i * 50.0f, 200.0f, 25.0f);
            UILabel *start = [[UILabel alloc] initWithFrame:startFrame];
            start.text = [dateMaker stringFromDate:e.start];
            [v addSubview:start];
            
            CGRect endFrame = CGRectMake(0.0f, i * 50.0f + 25.0f, 200.0f, 25.0f);
            UILabel *end = [[UILabel alloc] initWithFrame:endFrame];
            end.text = [dateMaker stringFromDate:e.end];
            [v addSubview:end];
        }
        
        self.view = v;
    }
    
    return self;
}

@end
