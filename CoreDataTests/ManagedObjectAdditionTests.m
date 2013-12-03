//
//  CoreDataTests.m
//  CoreDataTests
//

#import "VICoreDataManager.h"
#import "VIPerson.h"

NSString *const FIRST_NAME_DEFAULT_KEY = @"firstName";
NSString *const LAST_NAME_DEFAULT_KEY = @"lastName";
NSString *const BIRTHDAY_DEFAULT_KEY = @"birthDay";
NSString *const CATS_DEFAULT_KEY = @"numberOfCats";
NSString *const COOL_RANCH_DEFAULT_KEY = @"lovesCoolRanch";

NSString *const FIRST_NAME_CUSTOM_KEY = @"first";
NSString *const LAST_NAME_CUSTOM_KEY = @"last";
NSString *const BIRTHDAY_CUSTOM_KEY = @"date_of_birth";
NSString *const CATS_CUSTOM_KEY = @"cat_num";
NSString *const COOL_RANCH_CUSTOM_KEY = @"CR_PREF";

NSString *const FIRST_NAME_MALFORMED_KEY = @"first.banana";
NSString *const LAST_NAME_MALFORMED_KEY = @"somethingsomething.something.something";
NSString *const BIRTHDAY_MALFORMED_KEY = @"date_of_birth?";
NSString *const CATS_MALFORMED_KEY = @"cat_num_biz";
NSString *const COOL_RANCH_MALFORMED_KEY = @"CR_PREF";

NSString *const FIRST_NAME_KEYPATH_KEY = @"name.first";
NSString *const LAST_NAME_KEYPATH_KEY = @"name.last";
NSString *const BIRTHDAY_KEYPATH_KEY = @"birthday";
NSString *const CATS_KEYPATH_KEY = @"prefs.cats.number";
NSString *const COOL_RANCH_KEYPATH_KEY = @"prefs.coolRanch";

#import <XCTest/XCTest.h>

@interface ManagedObjectAdditionTests : XCTestCase

@end

@implementation ManagedObjectAdditionTests

- (void)setUp
{
    [super setUp];
    [[VICoreDataManager sharedInstance] resetCoreData];
    [[VICoreDataManager sharedInstance] setResource:@"VICoreDataModel" database:@"VICoreDataTestingModel.sqlite"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testImportExportDictionaryWithDefaultMapper
{
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForDefaultMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForDefaultMapper]];

    NSDictionary *dict = [person dictionaryRepresentation];
    XCTAssertTrue([dict isEqualToDictionary:[self makePersonDictForDefaultMapper]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportExportDictionaryWithCustomMapper
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForCustomMapper]];

    NSDictionary *dict = [person dictionaryRepresentation];
    XCTAssertTrue([dict isEqualToDictionary:[self makePersonDictForCustomMapper]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportExportDictionaryWithCustomKeyPathMapper
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArrayWithKeyPaths]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapperWithKeyPaths] forManagedObjectContext:nil];

    XCTAssertTrue(person != nil, @"person was not created");
    XCTAssertTrue([person isKindOfClass:[VIPerson class]], @"person is wrong class");
    XCTAssertTrue([person.firstName isEqualToString:@"CUSTOMFIRSTNAME"], @"person first name is incorrect");
    XCTAssertTrue([person.lastName isEqualToString:@"CUSTOMLASTNAME"], @"person last name is incorrect");
    XCTAssertTrue([person.numberOfCats isEqualToNumber:@876], @"person number of cats is incorrect");
    XCTAssertTrue([person.lovesCoolRanch isEqualToNumber:@YES], @"person lovesCoolRanch is incorrect");

    NSDate *birthdate = [[self customDateFormatter] dateFromString:@"24 Jul 83 14:16"];
    XCTAssertTrue([person.birthDay isEqualToDate:birthdate], @"person birthdate is incorrect");

    NSDictionary *dict = [person dictionaryRepresentationRespectingKeyPaths];
    XCTAssertTrue([dict isEqualToDictionary:[self makePersonDictForCustomMapperWithKeyPaths]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportArrayWithCustomMapper
{
    NSArray *array = @[[self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(VIPerson *obj, NSUInteger idx, BOOL *stop) {
        [self checkMappingForPerson:obj andDictionary:[self makePersonDictForCustomMapper]];
    }];
}

- (void)testImportArrayWithCustomMapperOnWriteBlock
{
    NSArray *array = @[[self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [VICoreDataManager writeToTemporaryContext:^(NSManagedObjectContext *tempContext) {
        [VIPerson addWithArray:array forManagedObjectContext:tempContext];
        dispatch_semaphore_signal(semaphore);
    } completion:NULL];
    [self waitForResponse:1 semaphore:semaphore];

    NSArray *arrayOfPeople = [VIPerson fetchAllForPredicate:nil forManagedObjectContext:nil];
    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(VIPerson *obj, NSUInteger idx, BOOL *stop) {
        [self checkMappingForPerson:obj andDictionary:[self makePersonDictForCustomMapper]];
    }];
}

- (void)testImportArrayWithDefaultMapper
{
    NSArray *array = @[[self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(VIPerson *obj, NSUInteger idx, BOOL *stop) {
        [self checkMappingForPerson:obj andDictionary:[self makePersonDictForDefaultMapper]];
    }];
}

- (void)testImportArrayWithCustomMapperMalformedInput
{
    NSArray *array = @[[self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapperWithMalformedInput],
                       [self makePersonDictForCustomMapper],
                       [self makePersonDictForCustomMapper]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");
    //just need to check the count and make sure it doesn't crash
}

- (void)testImportArrayWithDefaultMapperMalformedInput
{
    NSArray *array = @[[self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapperWithMalformedInput],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");
    //just need to check the count and make sure it doesn't crash
}

- (void)testImportArrayWithMalformedMapper
{
    NSArray *array = @[[self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapperWithMalformedInput],
                       [self makePersonDictForDefaultMapper],
                       [self makePersonDictForDefaultMapper]];

    NSArray *malformedMaps = @[[VIManagedObjectMap mapWithForeignKeyPath:FIRST_NAME_MALFORMED_KEY coreDataKey:FIRST_NAME_DEFAULT_KEY],
                            [VIManagedObjectMap mapWithForeignKeyPath:LAST_NAME_MALFORMED_KEY coreDataKey:LAST_NAME_DEFAULT_KEY],
                            [VIManagedObjectMap mapWithForeignKeyPath:BIRTHDAY_MALFORMED_KEY coreDataKey:BIRTHDAY_DEFAULT_KEY dateFormatter:[self customDateFormatter]],
                            [VIManagedObjectMap mapWithForeignKeyPath:CATS_MALFORMED_KEY coreDataKey:CATS_DEFAULT_KEY],
                            [VIManagedObjectMap mapWithForeignKeyPath:COOL_RANCH_MALFORMED_KEY coreDataKey:COOL_RANCH_DEFAULT_KEY]];
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:@"fart" andMaps:malformedMaps];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    NSArray *arrayOfPeople = [VIPerson addWithArray:array forManagedObjectContext:nil];

    XCTAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");
    //just need to check the count and make sure it doesn't crash
}

- (void)testImportWithCustomMapperAndAnEmptyInputValue
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:FIRST_NAME_DEFAULT_KEY andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForCustomMapper]];

    person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapperWithAnEmptyInputValues] forManagedObjectContext:nil];
    XCTAssertTrue(person.lastName == nil, @"the NSNull in the import dictionary did not overwrite the managed object's property");
    XCTAssertTrue(person.numberOfCats == nil, @"the missing value in the import dictionary did not overwrite the managed object's property");

    NSUInteger count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class]];
    XCTAssertTrue(count == 1, @"the unique key did not work correctly");
}

- (void)testImportWithDefaultMapperAndAnEmptyInputValue
{
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForDefaultMapperWithAnEmptyInputValues] forManagedObjectContext:nil];
    XCTAssertTrue(person.lastName == nil, @"the NSNull in the import dictionary did not overwrite the managed object's property");
    XCTAssertTrue([person.numberOfCats integerValue] == 0, @"the missing value in the import dictionary did not overwrite the managed object's property");
}

- (void)testCountMethods
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:LAST_NAME_DEFAULT_KEY andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];

    NSDictionary *dict1 = @{FIRST_NAME_CUSTOM_KEY : @"Bananaman",
                            LAST_NAME_CUSTOM_KEY : @"DotCom",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 19:16",
                            CATS_CUSTOM_KEY : @404,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict1 forManagedObjectContext:nil];

    NSUInteger count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class]];
    XCTAssertTrue(count == 1, @"VICoreDataManager count method is incorrect");

    NSDictionary *dict2 = @{FIRST_NAME_CUSTOM_KEY : @"Francis",
                            LAST_NAME_CUSTOM_KEY : @"Bolgna",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 19:16",
                            CATS_CUSTOM_KEY : @404,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict2 forManagedObjectContext:nil];

    count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class]];
    XCTAssertTrue(count == 2, @"VICoreDataManager count method is incorrect");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"Francis"];
    count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class] withPredicate:pred forContext:nil];
    XCTAssertTrue(count == 1, @"VICoreDataManager count with predicate method is incorrect");

    pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"Bananaman"];
    BOOL exists = [VIPerson existsForPredicate:pred forManagedObjectContext:nil];
    XCTAssertTrue(exists, @"existsForPredicate is incorrect");
}

- (void)testCustomMapperUniqueKeyAndOverwriteSetting
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:LAST_NAME_DEFAULT_KEY andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    
    NSDictionary *dict1 = @{FIRST_NAME_CUSTOM_KEY : @"SOMEGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @192,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict1 forManagedObjectContext:nil];
    
    NSDictionary *dict2 = @{FIRST_NAME_CUSTOM_KEY : @"SOMEGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY2",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @192,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict2 forManagedObjectContext:nil];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"SOMEGUY"];
    NSArray *array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    XCTAssertTrue([array count] == 2, @"unique person test array has incorrect number of people");

    NSDictionary *dict3 = @{FIRST_NAME_CUSTOM_KEY : @"ANOTHERGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @14,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict3 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    XCTAssertTrue([array count] == 1, @"unique key was not effective");
    XCTAssertTrue([[array[0] numberOfCats] isEqualToNumber:@14], @"unique key was effective but the person object was not updated");

    mapper.overwriteObjectsWithServerChanges = NO;
    NSDictionary *dict4 = @{FIRST_NAME_CUSTOM_KEY : @"ONE MORE GUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @777,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict4 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    XCTAssertTrue([array count] == 1, @"unique key was not effective");
    XCTAssertTrue([[array[0] numberOfCats] isEqualToNumber:@14], @"\"overwriteObjectsWithServerChanges = NO\" was ignored");

    mapper.overwriteObjectsWithServerChanges = YES;
    NSDictionary *dict5 = @{FIRST_NAME_CUSTOM_KEY : @"ONE MORE GUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @777,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict5 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    XCTAssertTrue([array count] == 1, @"unique key was not effective");
    XCTAssertTrue([[array[0] numberOfCats] isEqualToNumber:@777], @"\"overwriteObjectsWithServerChanges = NO\" was ignored");
}

#pragma mark - Convenience stuff
- (void)waitForResponse:(NSInteger)waitTimeInSeconds semaphore:(dispatch_semaphore_t)semaphore
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:waitTimeInSeconds];
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if (timeoutDate == [timeoutDate earlierDate:[NSDate date]]) {
            XCTAssertTrue(NO, @"Waiting for completion took longer than %ldsec", (long)waitTimeInSeconds);
            return;
        }
    }
}

- (void)checkMappingForPerson:(VIPerson *)person andDictionary:(NSDictionary *)dict
{
    XCTAssertTrue(person != nil, @"person was not created");
    XCTAssertTrue([person isKindOfClass:[VIPerson class]], @"person is wrong class");

    NSString *firstName = [dict objectForKey:FIRST_NAME_DEFAULT_KEY] ? [dict objectForKey:FIRST_NAME_DEFAULT_KEY] : [dict objectForKey:FIRST_NAME_CUSTOM_KEY];
    XCTAssertTrue([person.firstName isEqualToString:firstName], @"person first name is incorrect");

    NSString *lastName = [dict objectForKey:LAST_NAME_DEFAULT_KEY] ? [dict objectForKey:LAST_NAME_DEFAULT_KEY] : [dict objectForKey:LAST_NAME_CUSTOM_KEY];
    XCTAssertTrue([person.lastName isEqualToString:lastName], @"person last name is incorrect");

    NSNumber *cats = [dict objectForKey:CATS_DEFAULT_KEY] ? [dict objectForKey:CATS_DEFAULT_KEY] : [dict objectForKey:CATS_CUSTOM_KEY];
    XCTAssertTrue([person.numberOfCats isEqualToNumber:cats], @"person number of cats is incorrect");

    NSNumber *lovesCoolRanch = [dict objectForKey:COOL_RANCH_DEFAULT_KEY] ? [dict objectForKey:COOL_RANCH_DEFAULT_KEY] : [dict objectForKey:COOL_RANCH_CUSTOM_KEY];
    XCTAssertTrue([person.lovesCoolRanch isEqualToNumber:lovesCoolRanch], @"person lovesCoolRanch is incorrect");

    NSDate *birthdate = [[VIManagedObjectMap defaultDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_DEFAULT_KEY]];
    if (!birthdate) {
        birthdate = [[self customDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_CUSTOM_KEY]];
    }
    XCTAssertTrue([person.birthDay isEqualToDate:birthdate], @"person birthdate is incorrect");
}

- (NSString *)randomNumberString
{
    return [NSString stringWithFormat:@"%d",arc4random()%3000];
}

- (NSDictionary *)makePersonDictForDefaultMapper
{
    NSDictionary *dict = @{FIRST_NAME_DEFAULT_KEY :  @"BILLY",
                           LAST_NAME_DEFAULT_KEY : @"TESTCASE" ,
                           BIRTHDAY_DEFAULT_KEY : @"1983-07-24T03:22:15Z",
                           CATS_DEFAULT_KEY : @17,
                           COOL_RANCH_DEFAULT_KEY : @NO};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapper
{
    NSDictionary *dict = @{FIRST_NAME_CUSTOM_KEY : @"CUSTOM",
                           LAST_NAME_CUSTOM_KEY : @"MAPMAN",
                           BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                           CATS_CUSTOM_KEY : @192,
                           COOL_RANCH_CUSTOM_KEY : @YES};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapperWithKeyPaths
{
    NSDictionary *nameDict = @{@"first": @"CUSTOMFIRSTNAME",
                               @"last": @"CUSTOMLASTNAME"};
    NSDictionary *catsDict = @{@"number": @876};

    NSDictionary *prefsDict = @{@"cats": catsDict,
                                @"coolRanch": @YES};

    NSDictionary *dict = @{@"name": nameDict,
                           BIRTHDAY_KEYPATH_KEY : @"24 Jul 83 14:16",
                           @"prefs": prefsDict};
    return dict;
}

- (NSDictionary *)makePersonDictForDefaultMapperWithAnEmptyInputValues
{
    NSDictionary *dict = @{FIRST_NAME_DEFAULT_KEY :  @"BILLY",
                           LAST_NAME_DEFAULT_KEY :  [NSNull null],
                           BIRTHDAY_DEFAULT_KEY : @"1983-07-24T03:22:15Z",
                           COOL_RANCH_DEFAULT_KEY : @NO};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapperWithAnEmptyInputValues
{
    NSDictionary *dict = @{FIRST_NAME_CUSTOM_KEY : @"CUSTOM",
                           LAST_NAME_CUSTOM_KEY : [NSNull null],
                           BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                           COOL_RANCH_CUSTOM_KEY : @YES};
    return dict;
}

- (NSDictionary *)makePersonDictForDefaultMapperWithMalformedInput
{
    NSDictionary *dict = @{FIRST_NAME_DEFAULT_KEY :  @"BILLY",
                           LAST_NAME_DEFAULT_KEY : @"TESTCASE" ,
                           BIRTHDAY_DEFAULT_KEY : @"1983-07-24T03:22:15Z",
                           CATS_DEFAULT_KEY : @[@17],
                           COOL_RANCH_DEFAULT_KEY : @{@"something": @NO}};
    return dict;
}

- (NSDictionary *)makePersonDictForCustomMapperWithMalformedInput
{
    NSDictionary *dict = @{FIRST_NAME_CUSTOM_KEY : @"CUSTOM",
                           LAST_NAME_CUSTOM_KEY : @"MAPMAN",
                           BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 14:16",
                           CATS_CUSTOM_KEY : @{@"something": @192},
                           COOL_RANCH_CUSTOM_KEY : @[@YES]};
    return dict;
}


- (NSDateFormatter *)customDateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd' 'LLL' 'yy' 'HH:mm"];
    [df setTimeZone:[NSTimeZone localTimeZone]];
    return df;
}

- (NSArray *)customMapsArray
{
    return @[[VIManagedObjectMap mapWithForeignKeyPath:FIRST_NAME_CUSTOM_KEY coreDataKey:FIRST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:LAST_NAME_CUSTOM_KEY coreDataKey:LAST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:BIRTHDAY_CUSTOM_KEY coreDataKey:BIRTHDAY_DEFAULT_KEY dateFormatter:[self customDateFormatter]],
             [VIManagedObjectMap mapWithForeignKeyPath:CATS_CUSTOM_KEY coreDataKey:CATS_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:COOL_RANCH_CUSTOM_KEY coreDataKey:COOL_RANCH_DEFAULT_KEY]];
}

- (NSArray *)customMapsArrayWithKeyPaths
{
    return @[[VIManagedObjectMap mapWithForeignKeyPath:FIRST_NAME_KEYPATH_KEY coreDataKey:FIRST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:LAST_NAME_KEYPATH_KEY coreDataKey:LAST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:BIRTHDAY_KEYPATH_KEY coreDataKey:BIRTHDAY_DEFAULT_KEY dateFormatter:[self customDateFormatter]],
             [VIManagedObjectMap mapWithForeignKeyPath:CATS_KEYPATH_KEY coreDataKey:CATS_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKeyPath:COOL_RANCH_KEYPATH_KEY coreDataKey:COOL_RANCH_DEFAULT_KEY]];
}

@end