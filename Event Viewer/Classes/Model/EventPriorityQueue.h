
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

@class Event;

/**
 *	Priority queue implementation based on CFBinaryHeap,
 *	as detailed at http://three20.pypt.lt/cocoa-objective-c-priority-queue
 *
 *	For use in merging ordered arrays of Events in a k-way merge.
 */
@interface EventPriorityQueue : NSObject
{
	@private
	// Heap itself
	CFBinaryHeapRef _heap;
}

// Returns number of items in the queue
- (NSUInteger)count;

// Returns all (sorted) objects in the queue
- (NSArray *)allObjects;

// Adds an object to the queue
- (void)addObject:(Event *)object;

// Removes all objects from the queue
- (void)removeAllObjects;

// Removes the "top-most" (as determined by the callback sort function) object from the queue
// and returns it
- (Event *)nextObject;

// Returns the "top-most" (as determined by the callback sort function) object from the queue
// without removing it from the queue
- (Event *)peekObject;

@end
