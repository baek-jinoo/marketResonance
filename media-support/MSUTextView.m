//
//  MSUTextView.m
//  media-support
//
//  Created by Jinwoo Baek on 2/7/15.
//  Copyright (c) 2015 Jin. All rights reserved.
//

#import "MSUTextView.h"

@implementation MSUTextView

//- (instancetype)init;
//{
//    self = [super init];
//    if (self) {
//        _allowedSelectors = [NSMutableArray array];
//    }
//    return self;
//}
//
//- (id)initWithCoder:(NSCoder *)aDecoder;
//{
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        _allowedSelectors = [NSMutableArray array];
//    }
//    return self;
//}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender;
{
    BOOL returnValue = [super canPerformAction:action withSender:sender];
    if (action == @selector(cut:)) {
        returnValue = NO;
    } else if (action == @selector(copy:)) {
        returnValue = NO;
    } else if (action == @selector(_promptForReplace:)) {
        returnValue = NO;
    } else if (action == @selector(_define:)) {
        returnValue = NO;
    }
//    for (NSString *selectorName in self.allowedSelectors) {
//        if (NSStringFromSelector(action)  == selectorName) {
//            return YES;
//        }
//    }
    return returnValue;
}

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

@end
