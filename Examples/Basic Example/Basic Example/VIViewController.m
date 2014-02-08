//
//  VIViewController.m
//  CoreData
//

#import "VIViewController.h"
#import "VICoreDataManager.h"
#import "VIPerson.h"

@implementation VIViewController

- (void)loadView
{
    [super loadView];

    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(reloadData)];
    UIBarButtonItem *reloadInBackgroundButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                                          target:self
                                                                                          action:@selector(reloadDataInBackground)];
    UIBarButtonItem *deleteSomeStuffButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                           target:self
                                                                                           action:@selector(deleteDataInBackground)];

    self.navigationItem.rightBarButtonItems = @[reloadButton, reloadInBackgroundButton, deleteSomeStuffButton];

    [[VICoreDataManager sharedInstance] resetCoreData];
    [self setupDataSource];
    [self setupCustomMapper];
}

- (void)setupDataSource
{
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"numberOfCats" ascending:NO],
                                 [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];

    self.dataSource = [[VIPersonDataSource alloc] initWithPredicate:nil
                                                          cacheName:nil
                                                          tableView:self.tableView
                                                 sectionNameKeyPath:nil sortDescriptors:sortDescriptors
                                                managedObjectClass:[VIPerson class]];
}

- (void)setupCustomMapper
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd' 'LLL' 'yy' 'HH:mm"];
    [df setTimeZone:[NSTimeZone localTimeZone]];

    NSArray *maps = @[[VIManagedObjectMap mapWithForeignKeyPath:@"first" coreDataKey:@"firstName"],
                      [VIManagedObjectMap mapWithForeignKeyPath:@"last" coreDataKey:@"lastName"],
                      [VIManagedObjectMap mapWithForeignKeyPath:@"date_of_birth" coreDataKey:@"birthDay" dateFormatter:df],
                      [VIManagedObjectMap mapWithForeignKeyPath:@"cat_num" coreDataKey:@"numberOfCats"],
                      [VIManagedObjectMap mapWithForeignKeyPath:@"CR_PREF" coreDataKey:@"lovesCoolRanch"]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:@"lastName" andMaps:maps];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
}

- (void)reloadData
{
    //nil context is treated as main context
    [self loadDataWithContext:nil];
}

- (void)reloadDataInBackground
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSManagedObjectContext *backgroundContext = [[VICoreDataManager sharedInstance] temporaryContext];
        [self loadDataWithContext:backgroundContext];
        [[VICoreDataManager sharedInstance] saveAndMergeWithMainContext:backgroundContext];
    });
}

- (void)deleteDataInBackground
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSManagedObjectContext *backgroundContext = [[VICoreDataManager sharedInstance] temporaryContext];

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"lovesCoolRanch == YES"];
        NSArray *personArray = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:backgroundContext];
        [personArray enumerateObjectsUsingBlock:^(VIPerson *obj, NSUInteger idx, BOOL *stop) {
            [backgroundContext deleteObject:obj];
        }];
        [[VICoreDataManager sharedInstance] saveAndMergeWithMainContext:backgroundContext];
    });
}

- (void)loadDataWithContext:(NSManagedObjectContext *)context
{
    //MAKE 20 PEOPLE WITH A CUSTOM MAPPER
    int j = 0;
    while (j < 21 ) {
        NSLog(@"%@",[VIPerson addWithDictionary:[self dictForCustomMapper] forManagedObjectContext:context]);
        j++;
    }
}

#pragma mark - Fake Data Makers
- (NSDictionary *)dictForCustomMapper
{
    return @{@"first" :  [self randomString],
             @"last" : [self randomString],
             @"date_of_birth" : @"24 Jul 83 14:16",
             @"cat_num" : [self randomNumber],
             @"CR_PREF" : [self randomCoolRanchPreference]};
}

- (NSNumber *)randomCoolRanchPreference
{
    NSUInteger number = arc4random()%2;
    return @(number);
}

- (NSNumber *)randomNumber
{
    return @(arc4random()%30);
}

- (NSString *)randomString
{
    NSInteger numberOfChars = 7;
    char data[numberOfChars];
    for (int x=0; x < numberOfChars; data[x++] = (char)('A' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:numberOfChars encoding:NSUTF8StringEncoding];
}

@end
