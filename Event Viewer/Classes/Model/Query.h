
#import <Foundation/Foundation.h>

// Number of objects to create during stress testing
#define TEST_STACKS 0   // Number of stacks in each panel
#define TEST_BANDS 15    // Number of bands in each stack


/**
 *  Data model containing all "meta" categories that have been selected in the currently submitted query, along with all events returned by the query.
 *  Handles all interfacing with the database for the current query and the parsing of the returned events.
 */
@interface Query : NSObject

/**
 *  Immutable dictionary with keys: "Bands", "Stacks", "Panels". 
 *  Each key points to an array of all parameters of the current query for the key's category.
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
@property (nonatomic, copy) NSArray *eventArray;   
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
@property (nonatomic, assign) int timeScale;

- (id) initTestWithPanels:(int)panels;
- (int)panelNum;
- (int)stackNum;
- (int)bandNum;

// (Experimental) Pure C implementation of a 4-dimensional array (to attempt a speed-up of C-style for-loop iterations)
float ****create4D ( int max_x, int max_y, int max_r, int max_c );
void my_free( void *ptr );
void *my_malloc ( char *expr, size_t size );

@end