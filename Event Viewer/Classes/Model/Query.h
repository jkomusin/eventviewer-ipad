
#import <Foundation/Foundation.h>

@class DatabaseHandler;


/**
 *  Enumeration for the three root categories of queriable constraints in the system:
 *      - EVENT is for the events tree
 *      - LOCATION is for the locations tree
 *      - TIME is for the time tree
 */
enum QUERY_TIMESCALE
{
    QueryTimescaleInfinite = 3,
    QueryTimescaleYear = 2,
    QueryTimescaleMonth = 1,
    QueryTimescaleDay = 0
};


// Number of objects to create during stress testing
#define TEST_STACKS 0   // Number of stacks in each panel
#define TEST_BANDS 15    // Number of bands in each stack

/**
 *  Data model containing all "meta" categories that have been selected in the currently submitted query, along with all events returned by the query.
 *  Handles all interfacing with the database for the current query and the parsing of the returned events.
 */
@interface Query : NSObject <NSURLConnectionDataDelegate, UITableViewDataSource>

/**
 *  Immutable dictionary with keys: "Bands", "Stacks", "Panels". 
 *  Each key points to a mutable array of all parameters of the current query for the key's category.
 */
@property (nonatomic, copy) NSDictionary *selectedMetas;

/**
 *  Immutable 4-dimensional array of all events resulting from the current query.
 *  In traditional array notation, i.e. 'eventArray[][][][]':
 *  - [x][][][] specifies the panel number
 *  - [][x][][] specifies the stack number
 *  - [][][x][] specifies the band number
 *  - [][][][x] specifies the event number
 */
@property (nonatomic, copy) NSMutableArray *eventArray;   

/**
 *  4-dimensional array similar to eventArray's mapping.
 *  Instead contains two floats for each event as normalized drawing dimensions for event rects.
 */
//@property () float ****eventFloats;

/**
 *	Smallest unit of time in the current query, determines scale of timelines.
 *	Value must be an integer from -1 - 3, where:
 *	   -1 = undefined
 *		0 = database length
 *		1 = year
 *		2 = month
 *		3 = day
 */
@property (nonatomic, assign) enum QUERY_TIMESCALE timeScale;

- (id) initTestWithPanels:(NSInteger)panels;
- (id) initWithHandler:(DatabaseHandler *)dbHandler;

- (NSInteger)panelNum;
- (NSInteger)stackNum;
- (NSInteger)bandNum;

- (void)addConstraint:(Constraint *)constraint toArray:(enum UI_OBJECT)category;

- (void)queryForEventsWithCurrentConstraints;

// (Experimental) Pure C implementation of a 4-dimensional array (to attempt a speed-up of C-style for-loop iterations)
float ****create4D ( int max_x, int max_y, int max_r, int max_c );
void my_free( void *ptr );
void *my_malloc ( char *expr, size_t size );

@end
