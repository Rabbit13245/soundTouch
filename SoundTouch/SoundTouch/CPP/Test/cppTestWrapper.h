#ifndef cppTestWrapper_h
#define cppTestWrapper_h

#import <Foundation/Foundation.h>

@interface cppTestWrapper : NSObject

-(void) hello_world_cpp_wrapper;
-(int) sum_cpp_wrapper: (NSUInteger) a : (NSUInteger) b;
-(void) testLaunch_wrapper;

@end

#endif /* cppTestWrapper_h */
