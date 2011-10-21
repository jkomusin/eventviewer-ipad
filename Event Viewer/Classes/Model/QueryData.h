//
//  EventModel.h
//  Event Viewer
//
//  Created by admin on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QueryData : NSObject

@property (nonatomic, assign) NSDictionary *selectedMetas;  //keys: "Bands", "Stacks", "Panels"
@property (nonatomic, assign) int panelNum;                //number of panels

- (id) initTestWithPanels:(int)panels;

@end
