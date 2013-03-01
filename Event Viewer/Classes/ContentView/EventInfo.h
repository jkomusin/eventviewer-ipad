
#import <Foundation/Foundation.h>

@class Event;

/**
 *  Info pane to be displayed in a popover when an event's details are requested
 */
@interface EventInfo : UIViewController

- (id)initWithEventArray:(NSArray *)eventArr;

@end
