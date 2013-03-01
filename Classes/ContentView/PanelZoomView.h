
@class PanelDrawView;

/**
 *  The ScrollView within the ContentScrollView that contains all of the bands.
 *  Is responsible for zooming the bands, thus should only zoom and scroll left and right.
 */
@interface PanelZoomView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) PanelDrawView *panelDrawView;     // The static View in which all bands are drawn. Is the view that is zoomed and panned by this ScrollView.
@property (nonatomic, assign) CGRect originalFrame;             // The original frame of the view when drawn at zoomScale 1.0

//- (id)initWithFrame:(CGRect)frame forPanelIndex:(NSInteger)panelIndex stackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum;
- (void)sizeForStackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum;

- (void)zoomToScale:(float)zoomScale;

@end
