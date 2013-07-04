#define SUPERINIT if((self = [super init]) == nil) {return nil;}

#ifndef ASSIGN
#define	ASSIGN(object,value) ({ \
    id __object = (id)(object); \
    object = [((id)value) retain]; \
    [__object release]; \
})
#endif

#ifndef DESTROY
#define DESTROY(lvalue) ({ [lvalue release]; lvalue = nil; })
#endif

#define NILARG_EXCEPTION_TEST(arg) NSParameterAssert(arg != nil)

#define D(...) ({ \
    id __objects_and_keys[] = {__VA_ARGS__}; \
    size_t __objects_and_keys_count = sizeof(__objects_and_keys) / sizeof(id); \
    if ((__objects_and_keys_count % 2) != 0) \
    { \
	    [NSException raise: NSInvalidArgumentException \
					format: @"D() macro expects an even number of arguments!"]; \
    } \
    size_t __objects_count = __objects_and_keys_count / 2; \
    id __objects[__objects_count]; \
    id __keys[__objects_count]; \
    size_t __objects_iterator; \
    for (__objects_iterator = 0; __objects_iterator < __objects_count; __objects_iterator++) \
    { \
        __objects[__objects_iterator] = __objects_and_keys[2 * __objects_iterator]; \
        __keys[__objects_iterator] = __objects_and_keys[(2 * __objects_iterator) + 1]; \
    } \
    [NSDictionary dictionaryWithObjects: __objects forKeys: __keys count: __objects_count]; \
})

#define A(...) ({ \
    id __objects[] = {__VA_ARGS__}; \
    [NSArray arrayWithObjects: __objects \
						count: (sizeof(__objects)/sizeof(id))]; \
})

#define S(...) ({ \
    id __objects[] = {__VA_ARGS__}; \
    [NSSet setWithObjects: __objects \
					count: (sizeof(__objects)/sizeof(id))]; \
})

#define INDEXSET(...) ({ \
	NSMutableIndexSet *__result = [NSMutableIndexSet indexSet]; \
	const NSUInteger __indices[] = {__VA_ARGS__}; \
    const size_t __indices_count = sizeof(__indices) / sizeof(NSUInteger); \
	size_t __indices_iterator; \
	for (__indices_iterator = 0; __indices_iterator < __indices_count; __indices_iterator++) \
	{ \
		[__result addIndex: __indices[__indices_iterator]]; \
	} \
	[[[NSIndexSet alloc] initWithIndexSet: __result] autorelease]; \
})
