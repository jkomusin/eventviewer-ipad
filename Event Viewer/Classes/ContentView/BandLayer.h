
#import <QuartzCore/QuartzCore.h>

@protocol DataDelegate;
@protocol DrawDelegate;


/**
 *	Enum to simplify the START and END locations inside the 'floatArray' function's return value.
 */
enum EVENT_LOCATION_TYPE
{
	EventLocationStart = 0,
	EventLocationEnd = 1
};


/**
 *  Layers that contain all events and are resized along with the BandDrawView.
 *  Are all sublayers of the BandDrawView.
 */
@interface BandLayer : CATiledLayer

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> zoomDelegate;

/**
 *  0-based indices specifying the location of the band in the data model
 */
@property (nonatomic, assign) NSInteger stackNumber;
@property (nonatomic, assign) NSInteger bandNumber;


@end
