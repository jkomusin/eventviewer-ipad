//
//  ContentView.m
//  Event Viewer
//
//  Created by Joshua Komusin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PanelZoomView.h"
#import "PanelDrawView.h"
#import "ContentView.h"

@implementation ContentView
{
    float _zoomScale;           // Current scale of all subviews of the contentView
    float _newZoomScale;        // Zoom scale to be used during zooming, due to the manual management of transforms
	CGRect _originalFrame;       // Original width of the view (a little superficial, but included for added robustness)
}

OBJC_EXPORT BOOL isPortrait;                // Global variable set in ContentViewController to specify device orientation


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _zoomScale = 1.0f;
        _newZoomScale = 1.0f;
        _originalFrame = frame;
    }
    return self;
}


//- (void)setTransform:(CGAffineTransform)newValue;
//{   
//    if (isPortrait) return;
//    
//    // The 'a' value of the transform is the transform's new scale of the view, which is reset after the zooming action completes
//    //  newZoomScale should therefore be kept while zooming, and then zoomScale should be updated upon completion
//	_newZoomScale = _zoomScale * newValue.a;
//    
//	if (_newZoomScale < 1.0)
//		_newZoomScale = 1.0;
//	
//    // Resize self
//	self.frame = CGRectMake(self.frame.origin.x,
//                            self.frame.origin.y, 
//                            _originalFrame.size.width * _newZoomScale,
//                            _originalFrame.size.height * _newZoomScale);
//    
//    // Resize all panels
////    [CATransaction begin];
////    [CATransaction setDisableActions: YES];
//    for (UIView *v in self.subviews)
//    {
////        if ([v isKindOfClass:[PanelZoomView class]])
////        {
//            CGRect newFrame = ((PanelZoomView *)v).originalFrame;
//            newFrame.size.width = newFrame.size.width * _newZoomScale;
//            newFrame.size.height = newFrame.size.height * _newZoomScale;
//            if (((PanelZoomView *)v).panelDrawView.currentPanel != 0)
//            {
//                newFrame.origin.x = newFrame.origin.x * _newZoomScale;
//            }
////        }
//    }
//    
////    for (CATiledLayer *s in _stackLayerArray)
////    {
////        for (BandLayer *b in [s sublayers])
////        {
////            CGRect bandF = b.frame;
////            bandF.size.width = BAND_WIDTH * _newZoomScale;
////            
////            b.frame = bandF;
////            
////        }
////    }
////    [CATransaction commit];
//}

/**
 *  Inform the view that zooming has ceased, and therefore the next transforms will have their own reset frame of reference
 *  (i.e. they will begin at 1.0 again, rather than resuming where they left off at the end of zooming)
 *  To do so, simply set the current zoomScale to the previously modified newZoomScale
 */
//- (void)doneZooming
//{
//    _zoomScale = _newZoomScale;
//    for (UIView *v in self.subviews)
//    {
//        if ([v isKindOfClass:[PanelZoomView class]])
//        {
//            [v setNeedsDisplay];
//        }
//    }
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
