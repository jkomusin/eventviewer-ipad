
#import <Foundation/Foundation.h>

// Number of objects to create during stress testing
#define TEST_STACKS 4   // Number of stacks in each panel
#define TEST_BANDS 5    // Number of bands in each stack

@interface QueryData : NSObject

@property (nonatomic, copy) NSDictionary *selectedMetas;    // Static dictionary with keys: "Bands", "Stacks", "Panels". Contains all parameter of the current query.

- (id) initTestWithPanels:(int)panels;
- (int)panelNum;
- (int)stackNum;
- (int)bandNum;

@end
