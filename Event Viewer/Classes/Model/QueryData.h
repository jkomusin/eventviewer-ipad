
#import <Foundation/Foundation.h>

@interface QueryData : NSObject

@property (nonatomic, copy) NSDictionary *selectedMetas;    //keys: "Bands", "Stacks", "Panels"
@property (nonatomic, assign) int panelNum;                 //number of panels

- (id) initTestWithPanels:(int)panels;

@end
