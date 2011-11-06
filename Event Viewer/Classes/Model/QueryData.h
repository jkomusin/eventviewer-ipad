
#import <Foundation/Foundation.h>

// Number of objects to create during stress testing
#define TEST_STACKS 4   // Number of stacks in each panel
#define TEST_BANDS 5    // Number of bands in each stack

@interface QueryData : NSObject

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

- (id) initTestWithPanels:(int)panels;
- (int)panelNum;
- (int)stackNum;
- (int)bandNum;

@end
