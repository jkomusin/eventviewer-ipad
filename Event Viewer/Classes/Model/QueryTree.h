
#import <Foundation/Foundation.h>

@class DatabaseHandler;
@class Constraint;
@protocol TreeDelegate;


/**
 *  Enumeration for the three root categories of queriable constraints in the system:
 *      - EVENT is for the events tree
 *      - LOCATION is for the locations tree
 *      - TIME is for the time tree
 */
enum QUERY_TREE_CATEGORY
{
    QueryTreeCategoryEvents = 0,
    QueryTreeCategoryLocations = 1,
    QueryTreeCategoryTimes = 2
};

/**
 *  Data model for the tree of queriable constraints pulled from the database
 *  that can form a query.
 *  This object supplies the backing data for the SecondaryViewController's table.
 *  Represents a tree structure due to the drill-down nature of the table.
 *
 *  The number of levels in this tree should always be one more than the currently viewed table.
 *      This is so that we can determine whether or not a cell should have an indicator that
 *      there is a level following the current one or not.
 */
@interface QueryTree : NSObject <NSURLConnectionDataDelegate, UITableViewDataSource>
{
    
}

@property (nonatomic, strong) id<TreeDelegate> treeDelegate;

- (id)initWithHandler:(DatabaseHandler *)dbHandler;
- (NSString *)getCurrentTitle;
- (Constraint *)getConstraintAtIndex:(NSInteger)index;

- (void)drillDownToIndex:(NSInteger)index;
- (void)drillUpOne;
- (void)drillUpToRoot;

- (void)removeContraintAtIndex:(NSInteger)i;
- (void)addConstraint:(Constraint *)c;

@end
