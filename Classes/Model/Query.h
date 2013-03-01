
@class DatabaseHandler;
@protocol ContentDelegate;
@protocol QueryDelegate;

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
 *  Delegate that controls the updating of the UI elements composing the content.
 */
@property (nonatomic, strong) id<ContentDelegate> contentDelegate;

/**
 *	Delegate that controls the updating of the querying constraints.
 */
@property (nonatomic, strong) id<QueryDelegate> queryDelegate;

/**
 *  Immutable dictionary with keys: "Bands", "Stacks", "Panels". 
 *  Each key points to a mutable array of all parameters of the current query for the key's category.
 */
@property (atomic, copy) NSDictionary *selectedMetas;

/**
 *	Whether or not the contents of the related selectedMetas should be considered as sctive.
 *	Ex: If hidingSelectedStacks, there may be metas selected in the "Stacks" key of selectedMetas,
 *		but they should not be considered active for querying, etc. (therefore, hidden)
 */
@property (nonatomic, assign) BOOL hidingSelectedPanels;
@property (nonatomic, assign) BOOL hidingSelectedStacks;
@property (nonatomic, assign) BOOL hidingSelectedBands;

/**
 *  Mutable 4-dimensional array of all events resulting from the current query. Atomic to avoid concurrency problems when query results are being simultaneously returned and drawn.
 *  In traditional array notation, i.e. 'eventArray[][][][]':
 *  - [x][][][] specifies the panel number
 *  - [][x][][] specifies the stack number
 *  - [][][x][] specifies the band number
 *  - [][][][x] specifies the event number
 *
 *	NOTE: The lowest level of the array (i.e. the array holding the events) is immutable.
 */
@property (atomic, copy) NSMutableArray *eventArray;

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

/**
 *	Whether or not there is currently a query in progress
 */
@property (nonatomic, assign) BOOL isQuerying;

- (id) initTestWithPanels:(NSInteger)panels;
- (id) initWithHandler:(DatabaseHandler *)dbHandler;

- (NSInteger)panelNum;
- (NSInteger)stackNum;
- (NSInteger)bandNum;

- (void)addConstraint:(Constraint *)constraint toArray:(enum UI_OBJECT)category;

- (void)queryForEventsWithCurrentConstraints;

- (void)swapBandData:(NSInteger)i withBand:(NSInteger)j;
- (void)swapStackData:(NSInteger)i withStack:(NSInteger)j;
- (void)swapPanelData:(NSInteger)i withPanel:(NSInteger)j;
- (void)swapBinData:(enum UI_OBJECT)i withBin:(enum UI_OBJECT)j;

@end
