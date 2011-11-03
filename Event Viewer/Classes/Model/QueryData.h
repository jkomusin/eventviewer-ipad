
#import <Foundation/Foundation.h>

@interface QueryData : NSObject

@property (nonatomic, copy) NSDictionary *selectedMetas;    // Static dictionary with keys: "Bands", "Stacks", "Panels". Contains all parameter of the current query.

- (id) initTestWithPanels:(int)panels;
- (int)panelNum;

@end
