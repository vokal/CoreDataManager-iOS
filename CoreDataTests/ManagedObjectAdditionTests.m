//
//  CoreDataTests.m
//  CoreDataTests
//

#import "ManagedObjectAdditionTests.h"
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

@implementation ManagedObjectAdditionTests

- (void)setUp
{
    [[VICoreDataManager sharedInstance] setResource:@"VICoreDataModel" database:@"VICoreDataTestingModel.sqlite"];
}

- (void)tearDown
{
    [[VICoreDataManager sharedInstance] resetCoreData];
}

- (void)testImportExportDictionaryWithDefaultMapper
{
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForDefaultMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForDefaultMapper]];

    NSDictionary *dict = [person dictionaryRepresentation];
    STAssertTrue([dict isEqualToDictionary:[self makePersonDictForDefaultMapper]], @"dictionary representation failed to match input dictionary");
}

- (void)testImportExportDictionaryWithCustomMapper
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:nil andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForCustomMapper]];

    NSDictionary *dict = [person dictionaryRepresentation];
    STAssertTrue([dict isEqualToDictionary:[self makePersonDictForCustomMapper]], @"dictionary representation failed to match input dictionary");
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

    STAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

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

    STAssertTrue([arrayOfPeople count] == 5, @"person array has incorrect number of people");

    [arrayOfPeople enumerateObjectsUsingBlock:^(VIPerson *obj, NSUInteger idx, BOOL *stop) {
        [self checkMappingForPerson:obj andDictionary:[self makePersonDictForDefaultMapper]];
    }];
}

- (void)testImportWithCustomMapperAndAnEmptyInputValue
{
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:FIRST_NAME_DEFAULT_KEY andMaps:[self customMapsArray]];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPerson class]];
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapper] forManagedObjectContext:nil];
    [self checkMappingForPerson:person andDictionary:[self makePersonDictForCustomMapper]];

    person = [VIPerson addWithDictionary:[self makePersonDictForCustomMapperWithAnEmptyInputValues] forManagedObjectContext:nil];
    NSAssert(person.lastName == nil, @"the NSNull in the import dictionary did not overwrite the managed object's property");
    NSAssert(person.numberOfCats == nil, @"the missing value in the import dictionary did not overwrite the managed object's property");
}

- (void)testImportWithDefaultMapperAndAnEmptyInputValue
{
    VIPerson *person = [VIPerson addWithDictionary:[self makePersonDictForDefaultMapperWithAnEmptyInputValues] forManagedObjectContext:nil];
    NSAssert(person.lastName == nil, @"the NSNull in the import dictionary did not overwrite the managed object's property");
    NSAssert([person.numberOfCats integerValue] == 0, @"the missing value in the import dictionary did not overwrite the managed object's property");
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
    STAssertTrue(count == 1, @"VICoreDataManager count method is incorrect");

    NSDictionary *dict2 = @{FIRST_NAME_CUSTOM_KEY : @"Francis",
                            LAST_NAME_CUSTOM_KEY : @"Bolgna",
                            BIRTHDAY_CUSTOM_KEY : @"24 Jul 83 19:16",
                            CATS_CUSTOM_KEY : @404,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict2 forManagedObjectContext:nil];

    count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class]];
    STAssertTrue(count == 2, @"VICoreDataManager count method is incorrect");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"Francis"];
    count = [[VICoreDataManager sharedInstance] countForClass:[VIPerson class] withPredicate:pred forContext:nil];
    STAssertTrue(count == 1, @"VICoreDataManager count with predicate method is incorrect");

    pred = [NSPredicate predicateWithFormat:@"firstName == %@",  @"Bananaman"];
    BOOL exists = [VIPerson existsForPredicate:pred forManagedObjectContext:nil];
    STAssertTrue(exists, @"existsForPredicate is incorrect");
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
    STAssertTrue([array count] == 2, @"unique person test array has incorrect number of people");

    NSDictionary *dict3 = @{FIRST_NAME_CUSTOM_KEY : @"ANOTHERGUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @14,
                            COOL_RANCH_CUSTOM_KEY : @YES};
    [VIPerson addWithDictionary:dict3 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    STAssertTrue([array count] == 1, @"unique key was not effective");
    STAssertTrue([[array[0] numberOfCats] isEqualToNumber:@14], @"unique key was effective but the person object was not updated");

    mapper.overwriteObjectsWithServerChanges = NO;
    NSDictionary *dict4 = @{FIRST_NAME_CUSTOM_KEY : @"ONE MORE GUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @777,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict4 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    STAssertTrue([array count] == 1, @"unique key was not effective");
    STAssertTrue([[array[0] numberOfCats] isEqualToNumber:@14], @"\"overwriteObjectsWithServerChanges = NO\" was ignored");

    mapper.overwriteObjectsWithServerChanges = YES;
    NSDictionary *dict5 = @{FIRST_NAME_CUSTOM_KEY : @"ONE MORE GUY",
                            LAST_NAME_CUSTOM_KEY : @"GUY1",
                            BIRTHDAY_CUSTOM_KEY : @"18 Jul 83 14:16",
                            CATS_CUSTOM_KEY : @777,
                            COOL_RANCH_CUSTOM_KEY : @NO};
    [VIPerson addWithDictionary:dict5 forManagedObjectContext:nil];

    pred = [NSPredicate predicateWithFormat:@"lastName == %@",  @"GUY1"];
    array = [VIPerson fetchAllForPredicate:pred forManagedObjectContext:nil];
    STAssertTrue([array count] == 1, @"unique key was not effective");
    STAssertTrue([[array[0] numberOfCats] isEqualToNumber:@777], @"\"overwriteObjectsWithServerChanges = NO\" was ignored");
}

#pragma mark - Convenience stuff
- (void)checkMappingForPerson:(VIPerson *)person andDictionary:(NSDictionary *)dict
{
    STAssertTrue(person != nil, @"person was not created");
    STAssertTrue([person isKindOfClass:[VIPerson class]], @"person is wrong class");

    NSString *firstName = [dict objectForKey:FIRST_NAME_DEFAULT_KEY] ? [dict objectForKey:FIRST_NAME_DEFAULT_KEY] : [dict objectForKey:FIRST_NAME_CUSTOM_KEY];
    STAssertTrue([person.firstName isEqualToString:firstName], @"person first name is incorrect");

    NSString *lastName = [dict objectForKey:LAST_NAME_DEFAULT_KEY] ? [dict objectForKey:LAST_NAME_DEFAULT_KEY] : [dict objectForKey:LAST_NAME_CUSTOM_KEY];
    STAssertTrue([person.lastName isEqualToString:lastName], @"person last name is incorrect");

    NSNumber *cats = [dict objectForKey:CATS_DEFAULT_KEY] ? [dict objectForKey:CATS_DEFAULT_KEY] : [dict objectForKey:CATS_CUSTOM_KEY];
    STAssertTrue([person.numberOfCats isEqualToNumber:cats], @"person number of cats is incorrect");

    NSNumber *lovesCoolRanch = [dict objectForKey:COOL_RANCH_DEFAULT_KEY] ? [dict objectForKey:COOL_RANCH_DEFAULT_KEY] : [dict objectForKey:COOL_RANCH_CUSTOM_KEY];
    STAssertTrue([person.lovesCoolRanch isEqualToNumber:lovesCoolRanch], @"person lovesCoolRanch is incorrect");

    NSDate *birthdate = [[VIManagedObjectMap defaultDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_DEFAULT_KEY]];
    if (!birthdate) {
        birthdate = [[self customDateFormatter] dateFromString:[dict objectForKey:BIRTHDAY_CUSTOM_KEY]];
    }
    STAssertTrue([person.birthDay isEqualToDate:birthdate], @"person birthdate is incorrect");
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

- (NSDateFormatter *)customDateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd' 'LLL' 'yy' 'HH:mm"];
    [df setTimeZone:[NSTimeZone localTimeZone]];
    return df;
}

- (NSArray *)customMapsArray
{
    return @[[VIManagedObjectMap mapWithForeignKey:FIRST_NAME_CUSTOM_KEY coreDataKey:FIRST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKey:LAST_NAME_CUSTOM_KEY coreDataKey:LAST_NAME_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKey:BIRTHDAY_CUSTOM_KEY coreDataKey:BIRTHDAY_DEFAULT_KEY dateFormatter:[self customDateFormatter]],
             [VIManagedObjectMap mapWithForeignKey:CATS_CUSTOM_KEY coreDataKey:CATS_DEFAULT_KEY],
             [VIManagedObjectMap mapWithForeignKey:COOL_RANCH_CUSTOM_KEY coreDataKey:COOL_RANCH_DEFAULT_KEY]];
}

@end