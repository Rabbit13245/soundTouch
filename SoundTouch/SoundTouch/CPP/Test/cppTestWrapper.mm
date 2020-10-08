#import "cppTestWrapper.h"
#import "cppTest.hpp"

@implementation cppTestWrapper

-(void) hello_world_cpp_wrapper{
    cppTest cppTest;
    cppTest.hello_world_cpp();
}

-(int) sum_cpp_wrapper: (NSUInteger) a : (NSUInteger) b{
    cppTest cppTest;
    return cppTest.sum_cpp(int(a),int(b));
}

-(void)testLaunch_wrapper{
    cppTest cppTest;
    cppTest.testLaunch();
}


@end

