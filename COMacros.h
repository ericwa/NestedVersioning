#define SUPERINIT if((self = [super init]) == nil) {return nil;}

#define	ASSIGN(object,value)	({\
id __object = (id)(object); \
object = [((id)value) retain]; \
[__object release]; \
})

#define NILARG_EXCEPTION_TEST(arg) do { \
if (nil == arg) \
{ \
[NSException raise: NSInvalidArgumentException format: @"For %@, " \
"%s must not be nil", NSStringFromSelector(_cmd), #arg]; \
} \
} while(0);

#define D(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__ , nil]
#define A(...) [NSArray arrayWithObjects:__VA_ARGS__ , nil]
#define S(...) [NSSet setWithObjects:__VA_ARGS__ , nil]