//
//  ViewController.m
//  media-support
//
//  Created by Jinwoo Baek on 2/7/15.
//  Copyright (c) 2015 Jin. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "MSUTextView.h"

static int kNumberOfAlternatives = 5;
static NSString *kNoAlternatives = @"No Alternatives";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MSUTextView *textView;
@property (strong, nonatomic) NSMutableDictionary *actionDictionary;
@property (strong, nonatomic) NSDate *lastTimeSelectionChanged;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) NSString *currentRequest;

- (IBAction)copy:(id)sender;

@end

@implementation ViewController

- (void)copy:(id)sender;
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.textView.text;
    
    CGRect messageRect = CGRectMake(0, 0, 100, 50);
    UILabel *message = [[UILabel alloc] initWithFrame:messageRect];
    message.center = self.view.center;
    message.text = @"Copied";
    message.layer.borderWidth = 5.0f;
    message.layer.borderColor = [UIColor blueColor].CGColor;
    message.layer.cornerRadius = 7.0f;
    message.textAlignment = NSTextAlignmentCenter;
    message.alpha = 0.5f;
    [self.textView addSubview:message];
    [UIView animateWithDuration:1.5f animations:^{
        message.alpha = 0.0f;
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.actionDictionary = [NSMutableDictionary dictionary];
    self.textView.delegate = self;
    self.textView.allowsEditingTextAttributes = NO;
    self.textView.textContainerInset = UIEdgeInsetsMake(20.0f, 10.0f, 10.0f, 10.0f);
    
    BOOL flag = YES;
    NSMutableArray *gestureRecognizers = [NSMutableArray arrayWithCapacity:[self.textView.gestureRecognizers count]];
    for (UIGestureRecognizer *gestureRecognizer in self.textView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
            if (tapGestureRecognizer.numberOfTapsRequired == 2) {
                UITapGestureRecognizer *newTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textSelection)];
                newTapGestureRecognizer.numberOfTapsRequired = 2;
                newTapGestureRecognizer.delaysTouchesEnded = NO;
                [gestureRecognizers insertObject:newTapGestureRecognizer atIndex:0];
            }
        }
        if (flag) {
            [gestureRecognizers insertObject:gestureRecognizer atIndex:0];
        }
        flag = YES;
    }
    self.textView.gestureRecognizers = gestureRecognizers;
    [self updateMessageResonance];
}

- (void)titleAction:(id)sender;
{
    NSLog(@"title action method called with sender: [%@]", sender);
}

- (void)textSelection;
{
    NSLog(@"text selection");
}

- (void)textViewDidEndEditing:(UITextView *)textView;
{
    NSLog(@"text view did end editing");
    
}

- (void)updateMessageResonance;
{
    NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
    NSString *baseURL = @"https://gateway.watsonplatform.net/messageresonance/service/api/v1/ringscore";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Basic YTI3YTAyMjEtNWY0MC00NmZhLWIwNWEtN2NmZjIxZWM2NjEyOnNMaDVUSnFMM1o0ZQ==" forHTTPHeaderField:@"Authorization"];
    
    NSArray *words = [self.textView.text componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    
    for (NSString *word in words) {
        NSString *queryString = [NSString stringWithFormat:@"dataset=1&text=%@", word];
        NSString *urlString = [NSString stringWithFormat:@"%@?%@", baseURL, queryString];
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        request.URL = url;
        NSURLSessionDataTask *downloadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *requestError) {
            NSHTTPURLResponse *httpResponse;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                httpResponse = (NSHTTPURLResponse *)response;
            }
            if (!requestError && httpResponse.statusCode == 200) {
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSRange initialSelection = self.textView.selectedRange;
                    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                    NSNumber *overallNumber = responseDictionary[@"overall"];
                    CGFloat overall = [overallNumber floatValue];
                    
                    CGFloat red = (50.0f - overall) / 50.0f;
                    if (red > 1.0f) {
                        red = 1.0f;
                    }
                    CGFloat green = overall / 50;
                    if (green > 1.0f) {
                        green = 1.0f;
                    }
                    UIColor *color = [UIColor colorWithRed:red green:green blue:0.0f alpha:1.0f];
                    
                    NSRange range = [self.textView.text rangeOfString:word];
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
                    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
                    self.textView.attributedText = attributedString;
                    self.textView.selectedRange = initialSelection;
                });
                
            }
        }];
        [downloadTask resume];
    }
    
}

- (void)textViewDidChange:(UITextView *)textView;
{
    NSLog(@"text view did change");
    
    [self updateMessageResonance];
}

- (void)textViewDidChangeSelection:(UITextView *)textView;
{
    [UIMenuController sharedMenuController].menuItems = nil;
    self.currentRequest = [[NSUUID UUID] UUIDString];
    [self.activityIndicatorView removeFromSuperview];
    if (!self.lastTimeSelectionChanged) {
        self.lastTimeSelectionChanged = [NSDate dateWithTimeIntervalSince1970:0];
    }
    NSDate *currentDate = [NSDate date];
    NSComparisonResult comparisonResult = [self.lastTimeSelectionChanged compare:currentDate];
    if (comparisonResult == NSOrderedAscending && [currentDate timeIntervalSinceDate:self.lastTimeSelectionChanged] > 5.0) {
        __block NSMutableArray *menuItems;
        NSString *subString = [self.textView.text substringWithRange:self.textView.selectedRange];
        //Get alternative strings
        NSMutableArray *alternativePhrases = [NSMutableArray array];
        if ([subString length] > 0) {
            [self getSynonymsForString:subString array:alternativePhrases];
        
            [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
            UITextRange * selectionRange = [self.textView selectedTextRange];
            CGRect selectionStartRect = [self.textView caretRectForPosition:selectionRange.start];
            CGRect selectionEndRect = [self.textView caretRectForPosition:selectionRange.end];
            CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x)/2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
            
            CGRect activityIndicatorRect = CGRectMake(selectionCenterPoint.x - 20, selectionCenterPoint.y - 20, 40, 40);
            self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorRect];
            self.activityIndicatorView.color = [UIColor blueColor];
            [self.textView addSubview:self.activityIndicatorView];
            [self.activityIndicatorView startAnimating];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                NSString *currentRequestCopy = [self.currentRequest copy];
                while ([alternativePhrases count] < 1) {
                    [NSThread sleepForTimeInterval:0.2];
                }
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.activityIndicatorView removeFromSuperview];
                    if ([self.currentRequest isEqualToString:currentRequestCopy]) {
                        menuItems = [NSMutableArray arrayWithCapacity:kNumberOfAlternatives];
                        SEL fwd = @selector(forwarder:);
                        for (NSString *phrase in alternativePhrases) {
                            SEL sel = [self uniqueActionSelectorWithString:phrase];
                            [self.actionDictionary setObject:phrase forKey:NSStringFromSelector(sel)];
                            NSString *something = NSStringFromSelector(sel);
                            [self.actionDictionary setObject:phrase forKey:something];
                            class_addMethod([self class], sel, [[self class] instanceMethodForSelector:fwd], "v@:@");
                            UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:phrase action:sel];
                            [menuItems insertObject:menuItem atIndex:0];
                        }
                        UITextRange * selectionRange = [self.textView selectedTextRange];
                        CGRect selectionStartRect = [self.textView caretRectForPosition:selectionRange.start];
                        CGRect selectionEndRect = [self.textView caretRectForPosition:selectionRange.end];
                        
                        CGRect activityIndicatorRect = CGRectMake(selectionStartRect.origin.x, selectionStartRect.origin.y, selectionEndRect.origin.x - selectionStartRect.origin.x, selectionStartRect.size.height);
                        
                        [UIMenuController sharedMenuController].menuItems = menuItems;
                        [[UIMenuController sharedMenuController] setTargetRect:activityIndicatorRect inView:self.textView];
                        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
                    }
                });
            });
        }
        [UIMenuController sharedMenuController].menuItems = menuItems;
    }
}

- (void)forwarder:(UIMenuController *)mc {
    NSUInteger currentLocation = self.textView.selectedRange.location;
    NSString *replacementPhrase = [self.actionDictionary objectForKey:NSStringFromSelector(_cmd)];
    if (![replacementPhrase isEqualToString:kNoAlternatives]) {
        self.textView.text = [self.textView.text stringByReplacingCharactersInRange:self.textView.selectedRange withString:replacementPhrase];
    }
    
    NSUInteger newLocation = currentLocation;// + [replacementPhrase length];
    self.textView.selectedRange = NSMakeRange(newLocation, 0);
    
    [self updateMessageResonance];
    [UIMenuController sharedMenuController].menuItems = nil;
}

- (SEL)uniqueActionSelectorWithString:(NSString *)phrase {
    NSString *selString = [NSString stringWithFormat:@"menu_%@:", [phrase stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
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
            NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            if (responseArray) {
                NSArray *temporarySynonyms = responseArray.firstObject[@"synonyms"];
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
    self.lastTimeSelectionChanged = [NSDate date];
}

@end
