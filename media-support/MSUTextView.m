//
//  MSUTextView.m
//  media-support
//
//  Created by Jinwoo Baek on 2/7/15.
//  Copyright (c) 2015 Jin. All rights reserved.
//

#import "MSUTextView.h"

@implementation MSUTextView

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
    return returnValue;
}

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

@end
