/**
 RComposeBar.h
 The MIT License (MIT)
 Created by Rajeev Prasad on 11/6/16.
 Copyright © 2016 Rajeev Prasad <rjeprasad@gmail.com>. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

/** RComposeBarDelegate
 - delegate to handle basic compose bar user interaction feedbacks */
@protocol RComposeBarDelegate <NSObject>
@required
/** Send button tapped (only when text available on compose bar)
 @param Current text value on the compose bar */
- (void) composeBarSendDidTapped:(NSString *)text;
/** Compose bar height changed (base on user inputs - text/item/location input) */
- (void) composeBarHeightDidChange:(CGFloat)height;
@optional
/** Left button tapped */
- (void) composeBarLeftButtonTapped;
/** Right button tapped (only when textbox is empty)*/
- (void) composeBarRightButtomTapped:(NSInteger)tag;
/** Location is selected */
- (void) composeBarLocationSelected;
/** Text value changed in compose bar */
- (void) composeBarTextDidChanged:(NSString *)text;
/** Item at index should be deleted */
- (void) deleteComposeBarItemAtIndex:(NSInteger)index;
/** Item at index is selected */
- (void) selecteComposeBarItemAtIndex:(NSInteger)index;
/** Location should be deleted */
- (void) deleteComposeBarLocation;
/** Clear data triggred - you should cleat location and item data */
- (void) composeBarDidClear;
@end

/** RComposeBarDataSource
 - datasource to handle item list and location data */
@protocol RComposeBarDataSource <NSObject>
@optional
/** Number of items in item container */
- (NSInteger) numberOfItemsInComposeBar;
/** Image item at index at item container
 @return thumbnail image for item (image/video etc) must not be nil */
- (UIImage *) imageForComposeBarItemAtIndex:(NSInteger)index;
/** Location string to display on compose bar */
- (NSString *) locationInComposeBar; // location will be hidden when not set or returns nil
@end

@interface RComposeBar : UIView
/*! @brief object that act as a delegate for compose bar */
@property (nonatomic, weak) id<RComposeBarDelegate> delegate;

/*! @brief object that act as a dataSource for compose bar */
@property (nonatomic, weak) id<RComposeBarDataSource> dataSource;

/*! @brief Current text value */
@property (nonatomic, readonly) NSString *text;
/** Set compose bar text field value - this will overide current tetx value */
-(void)setText:(NSString *)text;

/*! @brief Placeholder text value */
@property (nonatomic, strong) NSString *placeholder;

/*! @brief Image for button on the left side of the textbox - left button will be hidded when image is nil */
@property (nonatomic, strong) UIImage *leftButtonImage;
/*! @brief Images for right button (send button will be visible when textbox is not empty)
 - Default nil - if image not available button will use 'sendTitle'
 - Send button cannot be removed
 - When text available image set by 'setRightButtonWithTag:::' will ge ignored and sendImage will display
 */
@property (nonatomic, strong) UIImage *sendImage;
/*! @brief Title for right button (send button will be visible when textbox is not empty)
 @remark Title text will ignore when 'sendImage' is available
 @remark Default 'Send'
 @remark Send button cannot be removed
 @remark When text available image set by 'setRightButtonWithTag:::' will ge ignored and sendImage will display
 @see -setRightButtonWithTag:image:backToKBImage:
 @see -setRightButtonWithTag:title:backToKBTitle:
 */
@property (nonatomic, strong) NSString *sendTitle;

/*! @brief Text color of the right button - Default  rgb(0,122,255) */
@property (nonatomic, strong) UIColor *buttonTextColor;

/*! @brief Background colors of enabled textbox and item container views - Default whiteColor */
@property (nonatomic, strong) UIColor *enabledBGColor;
/*! @brief Background colors of disabled textbox and item container views - Default whiteColor */
@property (nonatomic, strong) UIColor *disabledBGColor;

/*! @brief Top boarder line colors - Default white 0.8 */
@property (nonatomic, strong) UIColor *topLineColor;
/*! @brief Bottom boarder line colors - Default clearColor */
@property (nonatomic, strong) UIColor *bottomLineColor;

/*! @brief Text box border color - Default white 0.9 */
@property (nonatomic, strong) UIColor *textBoxBorderColor;

/*! @brief Disable compose bar - Default NO */
@property (nonatomic, assign) BOOL disable;

/*! @brief Disable compose bar text box and item container bar inputs - Default NO */
@property (nonatomic, assign) BOOL disableInput;
/*! @brief Disable right button - Default NO */
@property (nonatomic, assign) BOOL disableRightButton;
/*! @brief Disable left button - Default NO */
@property (nonatomic, assign) BOOL disableLeftButton;

/*! @brief Maximum heigth of the compose bar - Default 44 (to compatible with 44px default toolbar)
 - maxViewHeight >= maxTextHeight + insets + borders */
@property (nonatomic, assign) CGFloat maxHeight;

/*! @brief Text box font - Default systemFontOfSize:17 */
@property (nonatomic, strong) UIFont *font;

/** The designated initializer
 @remark you must use this method to initialize compose bar
 @param containerView view you are using to hold compose bar (ie. UIToolBar placed on top of the soft keybaord or bottom of teh screen)
 @param delegate object to act as a delegate */
-(instancetype) initWithContainer:(UIView *)containerView delegate:(id<RComposeBarDelegate>)delegate ;

/** Call to reload compose bar, if external properties are changed
 @remark if user add / delete item or location you must call this to reflect the changes */
-(void)reloadComposeBar;

/** set right button image
 @remark right button will display these images only when textbox is empty
 @param image right button image to display when text box is empty
 @param kbImage when right button tapped (ie. opened voice recorder) imr to go back to keyboard
 @remark 'kbimage' can be nil - grayed out 'image' will be used as 'kbimage'
 @remark see sample project for working example of a voice recorder
 @see -setRightButtonWithTag:title:backToKBTitle: */
-(void)setRightButtonWithTag:(NSInteger)tag image:(UIImage *)image backToKBImage:(UIImage *)kbImage;

/** set right button text
 @remark title text will be ignored is images are available
 @remark right button will display these title values only when textbox is empty
 @param title right button title to display when text box is empty
 @param kbTitle when right button tapped (ie. opened voice recorder) title to go back to keyboard
 @remark 'kbTitle' can be nil - grayed out 'title' will be used as 'kbTitle'
 @remark see sample project for working example of a voice recorder
 @see -setRightButtonWithTag:image:backToKBImage: */
-(void)setRightButtonWithTag:(NSInteger)tag title:(NSString *)title backToKBTitle:(NSString *)kbTitle;

/** Get the current height of the entire compose bar */
-(CGFloat) getCurrentHeight;

/** Clear all text and other input values from compose bar
 @remark delegate and dataSource values will not be cleared by compose bar */
-(void) clear;

-(instancetype) init __attribute__((unavailable("use -initWithContainer:delegate:")));
-(instancetype) initWithFrame:(CGRect)frame __attribute__((unavailable("use -initWithContainer:delegate:")));
-(instancetype) initWithCoder:(NSCoder *)aDecoder __attribute__((unavailable("use -initWithContainer:delegate:")));
@end