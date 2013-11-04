//
//  AGAlertViewWithProgressbar.h
//  AGAlertViewWithProgressbar
//
//  Created by Artur Grigor on 19.04.2012.
//  Copyright (c) 2012 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import <Foundation/Foundation.h>

@interface AGAlertViewWithProgressbar : NSObject<UIAlertViewDelegate>
{
    NSUInteger progress;
    NSString *title;
    NSString *message;
    NSString *cancelButtonTitle;
    NSArray *otherButtonTitles;
    UIAlertView *alertView;
    UIProgressView *progressView;
    UILabel *progressLabel;
    
    struct {
        unsigned int delegateClickedButtonAtIndex:1;
        unsigned int delegateCancel:1;
        unsigned int delegateWillPresentAlertView:1;
        unsigned int delegateDidPresentAlertView:1;
        unsigned int delegateWillDismissWithButtonIndex:1;
        unsigned int delegateDidDismissWithButtonIndex:1;
        unsigned int delegateShouldEnableFirstOtherButton:1;
    } supportedDelegateMethods;
    
}

@property (nonatomic, assign) NSUInteger progress;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *cancelButtonTitle;
@property (nonatomic, retain) NSArray *otherButtonTitles;
@property (nonatomic, assign) id<UIAlertViewDelegate> delegate;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;
@property (nonatomic, retain) UIAlertView *alertView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UILabel *progressLabel;

- (id)initWithTitle:(NSString *)theTitle message:(NSString *)theMessage andDelegate:(id<UIAlertViewDelegate>)theDelegate;
- (id)initWithTitle:(NSString *)theTitle message:(NSString *)theMessage delegate:(id)theDelegate cancelButtonTitle:(NSString *)titleForTheCancelButton otherButtonTitles:(NSString *)titleForTheFirstButton, ... NS_REQUIRES_NIL_TERMINATION;

- (void)show;
- (void)hide;

- (void)repositionControls;
- (void)setAutoresizingMask;
- (void)setupAlertView;
- (void)setProgress:(NSUInteger)theProgress withRange:(NSUInteger)range;

@end
