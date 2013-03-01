
#import "EventPriorityQueue.h"
#import "Event.h"

@implementation EventPriorityQueue

#pragma mark -
#pragma mark CFBinaryHeap functions for sorting the priority queue

static const void *EventObjectRetain(CFAllocatorRef allocator, const void *ptr)
{
    Event *event = (Event *)ptr;
    return [event retain];
}

static void EventRelease(CFAllocatorRef allocator, const void *ptr)
{
    Event *event = (Event *)ptr;
    [event release];
}

static CFStringRef EventDescription(const void* ptr)
{
    Event *event = (Event *)ptr;
    CFStringRef desc = (CFStringRef)[event description];
    return desc;
}

static CFComparisonResult EventCompare(const void* ptr1, const void* ptr2, void* context)
{
    Event *item1 = (Event *) ptr1;
    Event *item2 = (Event *) ptr2;
	
    // Sorting by starting location (Event's 'x' propery) in ascending order,
	//	followed by ending location (Event's 'x' property + 'width' propery) in ascending order.
	if ((item1.x < item2.x) ||
		((item1.x == item2.x) &&
		 (item1.endX < item2.endX)))
	{
		return kCFCompareLessThan;
    }
	else if ((item1.x == item2.x) &&
			 (item1.endX == item2.endX))
	{
		return kCFCompareEqualTo;
    }
	else
	{
        return kCFCompareGreaterThan;
    }
}

#pragma mark -
#pragma mark NSObject methods

- (id)init
{
    if ((self = [super init]))
	{
        CFBinaryHeapCallBacks callbacks;
        callbacks.version = 0;
		
        // Callbacks to the functions above
        callbacks.retain = EventObjectRetain;
        callbacks.release = EventRelease;
        callbacks.copyDescription = EventDescription;
        callbacks.compare = EventCompare;
		
        // Create the priority queue
        _heap = CFBinaryHeapCreate(kCFAllocatorDefault, 0, &callbacks, NULL);
    }
	
    return self;
}

- (void)dealloc
{
    if (_heap)
	{
        CFRelease(_heap);
    }
	
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"PriorityQueue = {%@}",
            (_heap ? [[self allObjects] description] : @"null")];
}

#pragma mark -
#pragma mark Queue methods

- (NSUInteger)count
{
    return CFBinaryHeapGetCount(_heap);
}

- (NSArray *)allObjects
{
    const void **arrayC = calloc(CFBinaryHeapGetCount(_heap), sizeof(void *));
    CFBinaryHeapGetValues(_heap, arrayC);
    NSArray *array = [NSArray arrayWithObjects:(id *)arrayC
                                         count:CFBinaryHeapGetCount(_heap)];
    free(arrayC);
    return array;
}

- (void)addObject:(Event *)object
{
    CFBinaryHeapAddValue(_heap, object);
}

- (void)removeAllObjects
{
    CFBinaryHeapRemoveAllValues(_heap);
}

- (Event *)nextObject
{
    Event *obj = [self peekObject];
    CFBinaryHeapRemoveMinimumValue(_heap);
    return obj;
}

- (Event *)peekObject
{
    return (Event *)CFBinaryHeapGetMinimum(_heap);
}

@end
