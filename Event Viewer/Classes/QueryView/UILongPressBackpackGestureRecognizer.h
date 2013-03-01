
#import <UIKit/UIKit.h>


/**
 *	GestureRecognizer that allows an object to be taken with it on its journey
 *	between views, etc.
 *	Useful in the dragging world, where the Recognizer may change hands, but needs
 *	to know where it came from once it arrives somewhere.
 */
@interface UILongPressBackpackGestureRecognizer : UILongPressGestureRecognizer
{
}

@property (nonatomic, strong) NSArray *storage;	// Array to be used as storage backpacking
											//	on top of the recognizer

@end
