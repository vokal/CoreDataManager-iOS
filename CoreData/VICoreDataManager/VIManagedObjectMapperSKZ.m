//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapperSKZ.h"
#import "VICoreDataManagerSKZ.h"
#import <objc/runtime.h>

@interface VIManagedObjectDefaultMapper : VIManagedObjectMapperSKZ
@end

@interface VIManagedObjectMapperSKZ()
@property (readwrite) NSArray *mapsArray;
@property (readwrite) NSDictionary *mapsInputKeyPathLookup;
@property (readwrite) NSDictionary *mapsCoreDataKeyLookup;
- (void)updateForeignComparisonKey;
- (id)checkNull:(id)inputObject;
- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter;
- (id)checkString:(id)outputObject withDateFormatter:(NSDateFormatter *)dateFormatter;
- (id)checkClass:(id)inputObject managedObject:(NSManagedObject *)object key:(NSString *)key;
- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key;
@end

@implementation VIManagedObjectMapperSKZ

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey andMaps:(NSArray *)mapsArray;
{
    VIManagedObjectMapperSKZ *mapper = [[self alloc] init];
    NSUInteger mapCount = mapsArray.count;
    
    id maps[mapCount];
    id inputKeyPaths[mapCount];
    id coreDataKeys[mapCount];
    NSUInteger i = 0;
    
    for ( VIManagedObjectMapSKZ *map in mapsArray )
    {
        maps[i] = map;
        inputKeyPaths[i] = map.inputKeyPath;
        coreDataKeys[i] = map.coreDataKey;
        i++;
    }
    
    mapper.mapsInputKeyPathLookup = [NSDictionary dictionaryWithObjects:maps forKeys:inputKeyPaths count:mapCount];
    mapper.mapsCoreDataKeyLookup = [NSDictionary dictionaryWithObjects:maps forKeys:coreDataKeys count:mapCount];
    
    [mapper setMapsArray:mapsArray];
    [mapper setUniqueComparisonKey:comparisonKey];
    return mapper;
}

- (nullable VIManagedObjectMapSKZ *)mapForInputKeyPath:(nonnull NSString *)inputKeyPath
{
    return self.mapsInputKeyPathLookup[inputKeyPath];
}

- (nullable VIManagedObjectMapSKZ *)mapForCoreDataKey:(NSString *)coreDataKey
{
    return self.mapsCoreDataKeyLookup[coreDataKey];
}

+ (instancetype)defaultMapper
{
    return [[VIManagedObjectDefaultMapper alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        _overwriteObjectsWithServerChanges = YES;
    }
    return self;
}

- (void)setUniqueComparisonKey:(NSString *)uniqueComparisonKey
{
    _uniqueComparisonKey = uniqueComparisonKey;
    _foreignUniqueComparisonKey = nil;
    if (uniqueComparisonKey) {
        [self updateForeignComparisonKey];
    }
}

- (void)setMapsArray:(NSArray *)mapsArray
{
    _mapsArray = mapsArray;
    _foreignUniqueComparisonKey = nil;
    if (mapsArray) {
        [self updateForeignComparisonKey];
    }
}

- (void)updateForeignComparisonKey
{
    [self.mapsArray enumerateObjectsUsingBlock:^(VIManagedObjectMapSKZ *aMap, NSUInteger idx, BOOL *stop) {
        if ([aMap.coreDataKey isEqualToString:self.uniqueComparisonKey]) {
            _foreignUniqueComparisonKey = aMap.inputKeyPath;
        }
    }];
}

#pragma mark - Description
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>\nMaps:%@\nUniqueKey:%@",
            NSStringFromClass([self class]),
            self,
            self.mapsArray,
            self.uniqueComparisonKey];
}

#pragma mark - Import Safety Checks

- (id)checkNull:(id)inputObject
{
    if ([[NSNull null] isEqual:inputObject]) {
        return nil;
    }
    return inputObject;
}

- (id)checkNumber:(id)inputObject withNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if (![inputObject isKindOfClass:[NSString class]]) {
        return inputObject;
    }

    //Bug: using DEFAULT mapper, if the input string COULD be made a number it WILL be made a number.
    //Be wary of the default mapper
    id number = [numberFormatter numberFromString:inputObject];
    return number ? number : inputObject;
}

- (id)checkDate:(id)inputObject withDateFormatter:(NSDateFormatter *)dateFormatter
{
    if (![inputObject isKindOfClass:[NSString class]]) {
        return inputObject;
    }
    id date = [dateFormatter dateFromString:inputObject];
    return date ? date : inputObject;
}

- (id)checkString:(id)outputObject withNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    if (![outputObject isKindOfClass:[NSNumber class]]) {
        return outputObject;
    }
    id numberString = [numberFormatter stringFromNumber:outputObject];
    return numberString ? numberString : outputObject;
}

- (id)checkString:(id)outputObject withDateFormatter:(NSDateFormatter *)dateFormatter
{
    if (![outputObject isKindOfClass:[NSDate class]]) {
        return outputObject;
    }
    id dateString = [dateFormatter stringFromDate:outputObject];
    return dateString ? dateString : outputObject;
}

- (id)checkClass:(id)inputObject managedObject:(NSManagedObject *)object key:(NSString *)key
{
    Class expectedClass = [self expectedClassForObject:object andKey:key];
    if (![inputObject isKindOfClass:expectedClass]) {
        
        if (inputObject != nil && ![inputObject isKindOfClass:[NSNull class]])
        {
            CDLog(@"Wrong kind of class for %@\nProperty: %@ \nExpected: %@\nReceived: %@",
                  [object class],
                  key,
                  NSStringFromClass(expectedClass),
                  NSStringFromClass([inputObject class]));
        }
        return nil;
    }
    return inputObject;
}

- (Class)expectedClassForObject:(NSManagedObject *)object andKey:(id)key
{
    NSDictionary *attributes = [[object entity] attributesByName];
    NSAttributeDescription *attributeDescription = [attributes valueForKey:key];
    NSString *className = [attributeDescription attributeValueClassName];
    if (!className) {
        const char *className = [[object.entity managedObjectClassName] cStringUsingEncoding:NSUTF8StringEncoding];
        const char *propertyName = [key cStringUsingEncoding:NSUTF8StringEncoding];
        
        Class managedObjectClass = objc_getClass(className);
        objc_property_t prop = class_getProperty(managedObjectClass, propertyName);
        
        NSString *attributeString = [NSString stringWithCString:property_getAttributes(prop) encoding:NSUTF8StringEncoding];
        const char *destinationClassName = [[self propertyTypeFromAttributeString:attributeString] cStringUsingEncoding:NSUTF8StringEncoding];
        
        return objc_getClass(destinationClassName);
    } else {
        return NSClassFromString(className);
    }
}

- (NSString *)propertyTypeFromAttributeString:(NSString *)attributeString
{
    NSString *type = [NSString string];
    NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];
    
    if ([typeScanner isAtEnd]) {
        return @"NULL";
    } else {
        [typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
        [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
        return type;
    }
}

@end

#pragma mark - Dictionary Input and Output
@implementation VIManagedObjectMapperSKZ (dictionaryInputOutput)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    [self.mapsArray enumerateObjectsUsingBlock:^(VIManagedObjectMapSKZ *aMap, NSUInteger idx, BOOL *stop) {
        id inputObject = [inputDict valueForKeyPath:aMap.inputKeyPath];
        inputObject = [self checkDate:inputObject withDateFormatter:aMap.dateFormatter];
        inputObject = [self checkNumber:inputObject withNumberFormatter:aMap.numberFormatter];
        inputObject = [self checkClass:inputObject managedObject:object key:aMap.coreDataKey];        
        inputObject = [self checkNull:inputObject];
        [object safeSetValueSKZ:inputObject forKey:aMap.coreDataKey];
    }];
}

- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object
{
    NSMutableDictionary *outputDict = [NSMutableDictionary new];
    [self.mapsArray enumerateObjectsUsingBlock:^(VIManagedObjectMapSKZ *aMap, NSUInteger idx, BOOL *stop) {
        id outputObject = [object valueForKey:aMap.coreDataKey];
        outputObject = [self checkString:outputObject withDateFormatter:aMap.dateFormatter];
        outputObject = [self checkString:outputObject withNumberFormatter:aMap.numberFormatter];
        if (outputObject) {
            outputDict[aMap.inputKeyPath] = outputObject;
        }
    }];
    
    return [outputDict copy];
}

NSString *const period = @".";
- (NSDictionary *)hierarchicalDictionaryRepresentationOfManagedObject:(NSManagedObject *)object
{
    NSMutableDictionary *outputDict = [NSMutableDictionary new];
    [self.mapsArray enumerateObjectsUsingBlock:^(VIManagedObjectMapSKZ *aMap, NSUInteger idx, BOOL *stop) {
        id outputObject = [object valueForKey:aMap.coreDataKey];
        outputObject = [self checkString:outputObject withDateFormatter:aMap.dateFormatter];
        outputObject = [self checkString:outputObject withNumberFormatter:aMap.numberFormatter];

        NSArray *components = [aMap.inputKeyPath componentsSeparatedByString:period];
        [self createNestedDictionary:outputDict fromKeyPathComponents:components];
        if (outputObject) {
            [outputDict setValue:outputObject forKeyPath:aMap.inputKeyPath];
        }
    }];

    return [outputDict copy];
}

- (void)createNestedDictionary:(NSMutableDictionary *)outputDict fromKeyPathComponents:(NSArray *)components
{
    __block NSMutableDictionary *nestedDict = outputDict;
    NSUInteger lastObjectIndex = [components count] - 1;
    [components enumerateObjectsUsingBlock:^(NSString *keyPathComponent, NSUInteger idx, BOOL *stop) {
        if(![nestedDict valueForKey:keyPathComponent] && idx < lastObjectIndex) {
            nestedDict[keyPathComponent] = [NSMutableDictionary dictionary];
        }
        nestedDict = [nestedDict valueForKey:keyPathComponent];
    }];
}

@end

#pragma mark - Dictionary Input and Output with the Default Mapper
@implementation VIManagedObjectDefaultMapper
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    //this default mapper assumes that local keys and entities match foreign keys and entities
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id inputObject = obj;
        inputObject = [self checkDate:inputObject withDateFormatter:[VIManagedObjectMapSKZ defaultDateFormatter]];
        inputObject = [self checkNumber:inputObject withNumberFormatter:[VIManagedObjectMapSKZ defaultNumberFormatter]];
        inputObject = [self checkClass:inputObject managedObject:object key:key];
        inputObject = [self checkNull:inputObject];
        [object safeSetValueSKZ:inputObject forKey:key];
    }];
}

- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object
{
    NSDictionary *attributes = [[object entity] attributesByName];
    NSMutableDictionary *outputDict = [NSMutableDictionary new];
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id outputObject = [object valueForKey:key];
        outputObject = [self checkString:outputObject withDateFormatter:[VIManagedObjectMapSKZ defaultDateFormatter]];
        if (outputObject) {
            outputDict[key] = outputObject;
        }
    }];
    
    return [outputDict copy];
}

- (NSDictionary *)hierarchicalDictionaryRepresentationOfManagedObject:(NSManagedObject *)object
{
    //the default mapper does not have key paths
    return [self dictionaryRepresentationOfManagedObject:object];
}

@end
