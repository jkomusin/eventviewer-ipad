
#import <UIKit/UIKit.h>

@class PanelZoomView;
@class ContentView;
@class Query;
@protocol DataDelegate;
@protocol DrawDelegate;

/**
 *  ScrollView containing all content in the currently displayed query results.
 *  Is the superview to all others, and the ContentViewController's primary view.
 */
@interface ContentScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> drawDelegate;    // Target for drawing delegation (must be set to the 0-indexed panel)
@property (nonatomic, strong) NSArray *panelZoomViews;          // Array of all zooming scrollviews representing the panels in the display
@property (nonatomic, strong) UIView *queryContentView;         // View containing all panels and content within the ContentScrollView as _contentView is reserved by UIScrollView :(

- (void)sizeForPanelNum:(NSInteger)panelNum stackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum;

- (void)switchToPanel:(NSInteger)panelIndex;

- (void)swapAllBandLabels:(NSInteger)draggingIndex and:(NSInteger)otherIndex skippingStack:(NSInteger)skipStackIndex areBothDragging:(BOOL)bothDragging;
- (void)swapStackLabels:(NSInteger)draggingIndex and:(NSInteger)otherIndex  whileDragging:(BOOL)dragging;
- (void)swapPanelLabels:(NSInteger)draggingIndex and:(NSInteger)otherIndex  whileDragging:(BOOL)dragging;

- (void)reorderPanel:(NSInteger)panelIndex withNewIndex:(NSInteger)index;

@end
