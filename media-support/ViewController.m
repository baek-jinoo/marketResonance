//
//  ViewController.m
//  media-support
//
//  Created by Jinwoo Baek on 2/7/15.
//  Copyright (c) 2015 Jin. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

static int kNumberOfAlternatives = 5;
static NSString *kNoAlternatives = @"No Alternatives";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) NSMutableDictionary *actionDictionary;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.actionDictionary = [NSMutableDictionary dictionary];
    self.textView.delegate = self;
    self.textView.allowsEditingTextAttributes = NO;
    self.textView.textContainerInset = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.textView becomeFirstResponder];
}

- (void)titleAction:(id)sender;
{
    NSLog(@"title action method called with sender: [%@]", sender);
}

- (void)textViewDidChangeSelection:(UITextView *)textView;
{
    NSMutableArray *menuItems;
    NSLog(@"text view did change selection");
    NSString *subString = [self.textView.text substringWithRange:self.textView.selectedRange];
    //Get alternative strings
    NSMutableArray *alternativePhrases = [NSMutableArray array];
    if ([subString length] > 0) {
        [self getSynonymsForString:subString array:alternativePhrases];
    
        while ([alternativePhrases count] < 1) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        menuItems = [NSMutableArray arrayWithCapacity:kNumberOfAlternatives];
        Class cls = [self class];
        SEL fwd = @selector(forwarder:);
        for (NSString *phrase in alternativePhrases) {
            SEL sel = [self uniqueActionSelectorWithString:phrase];
            // assuming keys not being retained, otherwise use NSValue:
//            [self.actionDictionary setObject:phrase forKey:NSStringFromSelector(sel)];
            NSString *something = NSStringFromSelector(sel);
            [self.actionDictionary setObject:phrase forKey:something];
            class_addMethod(cls, sel, [cls instanceMethodForSelector:fwd], "v@:@");
            UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:phrase action:sel];
            [menuItems insertObject:menuItem atIndex:0];
            // now add menu item with sel as the action
        }
    }
    [UIMenuController sharedMenuController].menuItems = menuItems;
}

- (void)forwarder:(UIMenuController *)mc {
    NSLog(@"Phrase for item is: %@", [self.actionDictionary objectForKey:NSStringFromSelector(_cmd)]);
    NSLog(@"the selector for item is: %@", NSStringFromSelector(_cmd));
    
}

- (SEL)uniqueActionSelectorWithString:(NSString *)phrase {
    NSString *selString = [NSString stringWithFormat:@"menu_%@:", phrase];
    SEL sel = sel_registerName([selString UTF8String]);
    return sel;
}

- (void)getSynonymsForString:(NSString *)string array:(NSMutableArray *)alternativePhrases;
{
    NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
    
    NSURL *url = [NSURL URLWithString:@"https://watson-tone-demo.mybluemix.net/tone-analyzer-beta/api/v1/synonym"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Basic OGExZDg3ZjEtNWQyMC00NmMzLWFhYTQtNjg5YTA5NWI1NzRmOlYzczNmY1BYQjgxMg==" forHTTPHeaderField:@"Authorization"];
    NSDictionary *dictionary = @{@"words": @[string], @"traits": @[@"openness"], @"limit": @(kNumberOfAlternatives)};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        NSLog(@"error in the data");
    }
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *requestError) {
        NSHTTPURLResponse *httpResponse;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
             httpResponse = (NSHTTPURLResponse *)response;
        }
        if (!requestError && httpResponse.statusCode == 200) {
            NSArray *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            NSLog(@"the returned dictionary: %@", responseDictionary);
            if (responseDictionary) {
                NSArray *temporarySynonyms = responseDictionary.firstObject[@"synonyms"];
                for (NSDictionary *synonym in temporarySynonyms) {
                    [alternativePhrases insertObject:synonym[@"word"] atIndex:0];
                }
                if ([alternativePhrases count] < 1) {
                    [alternativePhrases insertObject:kNoAlternatives atIndex:0];
                }
            }
        } else {
            //error condition
        }
    }];
    [uploadTask resume];
}

@end
