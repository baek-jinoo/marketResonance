//
//  MSUMenuItemView.m
//  media-support
//
//  Created by Jinwoo Baek on 2/8/15.
//  Copyright (c) 2015 Jin. All rights reserved.
//

#import "MSUMenuItemView.h"

@implementation MSUMenuItemView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *theTouch = [touches anyObject];
    if ([theTouch tapCount] == 2) {
        [self becomeFirstResponder];
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Change Color" action:@selector(changeColor:)];
        UIMenuController *menuCont = [UIMenuController sharedMenuController];
        [menuCont setTargetRect:self.frame inView:self.superview];
        menuCont.arrowDirection = UIMenuControllerArrowLeft;
        menuCont.menuItems = [NSArray arrayWithObject:menuItem];
        [menuCont setMenuVisible:YES animated:YES];
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {}

- (BOOL)canBecomeFirstResponder { return YES; }

- (void)changeColor:(id)sender {
    if ([self.viewColor isEqual:[UIColor blackColor]]) {
        self.viewColor = [UIColor redColor];
    } else {
        self.viewColor = [UIColor blackColor];
    }
    [self setNeedsDisplay];
}

@end
