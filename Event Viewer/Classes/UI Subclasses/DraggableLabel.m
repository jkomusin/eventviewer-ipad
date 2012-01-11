//
//  DraggableLabel.m
//  Event Viewer
//
//  Created by Home on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DraggableLabel.h"

@implementation DraggableLabel

/**
 *  Draws the label with draggable-indicator
 */
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0f);
	CGContextSetRGBStrokeColor(context, 0.75f, 0.75f, 0.75f, 1.0f);
    CGContextSetRGBFillColor(context, 0.75f, 0.75f, 0.75f, 1.0f);
    
    CGContextSaveGState(context);
    
    CGSize textSize = [self.text sizeWithFont:self.font];
    
    // Find y-coordinates of three ribs and draw them
    float heightF = self.frame.size.height;
    float y = (heightF - 11.0f) / 2.0f;
    for (int i = 0; i < 3; i++)
    {
        int drawY = y + (4.0f * i) + 0.5f;
        int drawX = 0;
        if (self.textAlignment == UITextAlignmentRight) // Label is for a Band
        {
//            CGContextMoveToPoint(context, drawX, drawY); 
//            CGContextAddLineToPoint(context, drawX + 15.0f, drawY);
//            CGContextStrokePath(context);
            drawX = self.frame.size.width - textSize.width - 20.0f + 0.5f;
        }
        else if (self.textAlignment == UITextAlignmentLeft) // Label is for a Stack
        {
//            float drawX = textSize.width + 5.0f + 0.5f;
            drawX = 0;
        }
        else if (self.textAlignment == UITextAlignmentCenter) // Label is for a Panel
        {
            drawX = (self.frame.size.width - textSize.width) / 2.0f - 20.0f;
        }
        CGRect dot1 = CGRectMake((float)drawX, drawY, 1.0f, 2.0f);
        CGContextFillRect(context, dot1);
        CGRect dot2 = CGRectMake((float)drawX + 5.0f, drawY, 1.0f, 2.0f);
        CGContextFillRect(context, dot2);
    }
    
    CGContextRestoreGState(context);
}

@end
