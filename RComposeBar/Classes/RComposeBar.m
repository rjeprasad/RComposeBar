/**
 RComposeBar.m
 The MIT License (MIT)
 Created by Rajeev Prasad on 11/6/16.
 Copyright © 2016 Rajeev Prasad <rjeprasad@gmail.com>.
 
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

#import "RComposeBar.h"
#import <AVFoundation/AVFoundation.h>

@interface RComposeBar() <UITextViewDelegate> {
    
}
@property (nonatomic, strong) UIView *containerView; // container of the full compose bar

@property (nonatomic, strong) UIView *topLine;

@property (nonatomic, strong) UIView *contentView; // view containing textbox and item container
@property (nonatomic, strong) UIScrollView *topView; // item container scroller
@property (nonatomic, strong) UIView *locationView;
@property (nonatomic, strong) UIView *separator; // separator between topview and text box
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;

@property (nonatomic, strong) UIView *bottomLine;

@property (nonatomic, strong) NSMutableArray *thumbUIs;
@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) UIButton *locationClose;

@property (nonatomic, strong) NSLayoutConstraint *textViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *topViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *locViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *separatorHeight;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonWidth; // default 0
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWidth; // default 0

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, assign) NSInteger alternateRightTag;
@property (nonatomic, strong) UIImage *alternateRightImage;
@property (nonatomic, strong) UIImage *alternateKBImage;

@property (nonatomic, strong) NSString *alternateRightText;
@property (nonatomic, strong) NSString *alternateKBText;

@end

static CGFloat initialHeight = 44.0;
static CGFloat topLineHeight = 0.5;
static CGFloat bottomLineHeight = 0.5;
static CGFloat separatorHeight = 0.5;
static CGFloat topBottomGap = 7.0;
static CGFloat topHeight = 70.0;
static CGFloat locHeight = 25.0;

@implementation RComposeBar

-(instancetype)initWithContainer:(UIView *)containerView delegate:(id<RComposeBarDelegate>)delegate {
    self = [super initWithFrame:containerView.frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _containerView = containerView;
        _delegate = delegate;
        _containerView.clipsToBounds = YES;
        [_containerView addSubview:self];
        NSDictionary *dic = @{@"VIEW": self};
        [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[VIEW]|" options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
        [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[VIEW]|" options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
        
        self.disableInput = NO;
        self.disableLeftButton = NO;
        self.disableRightButton = NO;
        self.disable = NO;
        self.thumbUIs = [NSMutableArray array];
        
        [self layoutComposeBar];
    }
    return self;
}

-(void)leftButtonTapped:(UIButton *)sender {
    [self.delegate composeBarLeftButtonTapped];
}

-(void)rightButtonTapped:(UIButton *)sender {
    if (_text && _text.length > 0) {
        [self.delegate composeBarSendDidTapped:_text];
        [self clear];
    } else {
        if (!_rightButton.selected) {
            [self.delegate composeBarRightButtomTapped:_alternateRightTag];
            _rightButton.selected = YES;
        } else {
            _rightButton.selected = NO;
            [self becomeFirstResponder];
        }
    }
}

-(BOOL)becomeFirstResponder {
    return [[self textView] becomeFirstResponder];
}

-(BOOL)resignFirstResponder {
    return [[self textView] resignFirstResponder];
}

-(void)setText:(NSString *)text {
    _text = text;
    _placeholderLabel.hidden = (text.length > 0);
    [self adjustUIHeights];
    [self setRightButtonTypeLocal];
}

-(void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    [self placeholderLabel].text = _placeholder;
}

-(void)setDisableInput:(BOOL)disableInput {
    _disableInput = disableInput;
    [self setInputDisableStatus];
}

-(void)setInputDisableStatus {
    if (!_enabledBGColor) _enabledBGColor = [UIColor whiteColor];
    if (!_disabledBGColor) _disabledBGColor = [UIColor clearColor];
    
    _topView.backgroundColor = _disableInput ? _disabledBGColor : _enabledBGColor;
    _textView.backgroundColor = _disableInput ? _disabledBGColor : _enabledBGColor;
    
    _textView.editable = !_disableInput;
}

-(void)setDisableLeftButton:(BOOL)disableLeftButton {
    _disableLeftButton = disableLeftButton;
    _leftButton.enabled = !_disableLeftButton;
}

-(void)setDisableRightButton:(BOOL)disableRightButton {
    _disableRightButton = disableRightButton;
    _rightButton.enabled = !_disableRightButton;
}

-(void)setLeftButtonImage:(UIImage *)leftButtonImage {
    _leftButtonImage = leftButtonImage;
    [_leftButton setImage:_leftButtonImage forState:UIControlStateNormal];
    _leftButtonWidth.constant = [self getImageWidth:leftButtonImage];
    [self layoutIfNeeded];
}

-(void)setRightButtonWithTag:(NSInteger)tag image:(UIImage *)image backToKBImage:(UIImage *)kbImage {
    _alternateRightTag = tag;
    _alternateRightImage = image;
    _alternateKBImage = kbImage;
    [self setRightButtonTypeLocal];
}

-(void)setRightButtonWithTag:(NSInteger)tag title:(NSString *)title backToKBTitle:(NSString *)kbTitle {
    _alternateRightTag = tag;
    _alternateRightText = title;
    _alternateKBText = kbTitle;
    [self setRightButtonTypeLocal];
}

-(void)setTopLineColor:(UIColor *)topLineColor {
    _topLineColor = topLineColor;
    _topLine.backgroundColor = [self getTopLineColor];
}

-(void)setBottomLineColor:(UIColor *)bottomLineColor {
    _bottomLineColor = bottomLineColor;
    _bottomLine.backgroundColor = [self getBottomLineColor];
}

-(UIFont *)font {
    if (!_font) {
        return [UIFont systemFontOfSize:17];
    }
    return _font;
}

-(void)clear {
    [self setText:@""];
    if ([self.delegate respondsToSelector:@selector(composeBarDidClear)]) {
        [_delegate composeBarDidClear];
    }
    [self reloadComposeBar];
}

#pragma mark setup initial UI components and constraints
-(void) layoutComposeBar {
    
    NSArray *array = self.subviews;
    for(UIView *v in array) { [v removeConstraints:[v constraints]]; }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[self topLine] forKey:@"TOPLINE"];
    [dic setObject:[self topView] forKey:@"TOPVIEW"];
    [dic setObject:[self locationView] forKey:@"LOCVIEW"];
    [dic setObject:[self separator] forKey:@"SEPARATOR"];
    [dic setObject:[self textView] forKey:@"TEXTVIEW"];
    [dic setObject:[self bottomLine] forKey:@"BOTTOMLINE"];
    [dic setObject:[self contentView] forKey:@"CONTENTVIEW"];
    [dic setObject:[self leftButton] forKey:@"LEFTBUTTON"];
    [dic setObject:[self rightButton] forKey:@"RIGHTBUTTON"];
    
    [self setPlaceholderView];
    
    // verticle alignment all base views
    NSString *constraintString = [NSString stringWithFormat:@"V:|[TOPLINE(%f)]-%f-[CONTENTVIEW]-%f-[BOTTOMLINE(%f)]|", topLineHeight, topBottomGap, topBottomGap, bottomLineHeight];
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:constraintString
                                                                  options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dic]];
    // horizontal alignment of all base views
    NSString *horConstString = @"H:|[LEFTBUTTON][CONTENTVIEW][RIGHTBUTTON]|";
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horConstString
                                                                 options:0 metrics:nil views:dic]];
    
    // verticle alignment all content views
    [[self contentView] addConstraints: [NSLayoutConstraint
                                         constraintsWithVisualFormat: @"V:|[TOPVIEW][LOCVIEW][SEPARATOR][TEXTVIEW]|"
                                         options:NSLayoutFormatAlignAllCenterX metrics:nil views:dic]];
    
    // horizontal alignment of lines
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[TOPLINE]|"
                                                                 options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[BOTTOMLINE]|"
                                                                 options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    // horizontal alignment to content views
    [[self contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[TOPVIEW]|"
                                                                               options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    [[self contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[LOCVIEW]|"
                                                                               options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    [[self contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[SEPARATOR]|"
                                                                               options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    [[self contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[TEXTVIEW]|"
                                                                               options:NSLayoutFormatAlignAllTop metrics:nil views:dic]];
    
    // verticle alignment to content views
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[LEFTBUTTON(44.0)]|"
                                                                 options:NSLayoutFormatAlignAllLeft metrics:nil views:dic]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[RIGHTBUTTON(44.0)]|"
                                                                 options:NSLayoutFormatAlignAllRight metrics:nil views:dic]];
    
    _textViewHeight = [NSLayoutConstraint
                       constraintWithItem:_textView
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0
                       constant:(initialHeight-(topBottomGap+topBottomGap+topLineHeight+bottomLineHeight))];
    [_textView addConstraint:_textViewHeight];
    
    _topViewHeight = [NSLayoutConstraint constraintWithItem:_topView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
    [_topView addConstraint:_topViewHeight];
    
    _locViewHeight = [NSLayoutConstraint constraintWithItem:_locationView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
    [_locationView addConstraint:_locViewHeight];
    
    _separatorHeight = [NSLayoutConstraint constraintWithItem:_separator attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
    [_separator addConstraint:_separatorHeight];
    
    // button sizes
    NSLayoutConstraint *rightH = [NSLayoutConstraint constraintWithItem:_rightButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:36];
    [_rightButton addConstraint:rightH];
    
    NSLayoutConstraint *leftH = [NSLayoutConstraint constraintWithItem:_leftButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:36];
    [_leftButton addConstraint:leftH];
    
    _rightButtonWidth = [NSLayoutConstraint constraintWithItem:_rightButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16];
    [_rightButton addConstraint:_rightButtonWidth];
    
    _leftButtonWidth = [NSLayoutConstraint constraintWithItem:_leftButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16];
    [_leftButton addConstraint:_leftButtonWidth];
    
    
    [self layoutIfNeeded];
    
    [self setRightButtonTypeLocal];
    [self setInputDisableStatus];
    [self sendFrameChangeFeedback];
    
    [self reloadComposeBar];
}

-(void)reloadComposeBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createTopItems];
        [self createLocationItem];
        [self adjustUIHeights];
    });
}

-(CGFloat)getCurrentHeight {
    return topLineHeight + bottomLineHeight + topBottomGap + topBottomGap + _textViewHeight.constant + _topViewHeight.constant + _locViewHeight.constant + _separatorHeight.constant;
}

-(void)adjustUIHeights {
    BOOL hasItems = NO;
    BOOL hasLocation = NO;
    
    CGFloat topConstH = 0;
    CGFloat locConstH = 0;
    CGFloat sepConstH = 0;
    
    if ([_dataSource respondsToSelector:@selector(numberOfItemsInComposeBar)]) {
        NSInteger itemCount = [_dataSource numberOfItemsInComposeBar];
        if (itemCount > 0) {
            hasItems = YES;
            topConstH = topHeight;
        }
    }
    
    if ([_dataSource respondsToSelector:@selector(locationInComposeBar)]) {
        NSString *location = [_dataSource locationInComposeBar];
        if (location && location.length > 0) {
            hasLocation = YES;
            locConstH = locHeight;
        }
    }
    
    if (hasItems || hasLocation){
        sepConstH= separatorHeight;
    }
    
    _textView.text = _text;
    
    CGFloat maxHeight = self.maxHeight;
    CGFloat maxTextHeight = maxHeight - (topLineHeight + bottomLineHeight + topBottomGap + topBottomGap + _topViewHeight.constant + _locViewHeight.constant + _separatorHeight.constant);
    
    CGFloat curTextHeight = [self textHeight];
    
    CGFloat textHeight = curTextHeight;
    if (curTextHeight > maxTextHeight) {
        textHeight = maxTextHeight;
    }
    
    _textViewHeight.constant = textHeight;
    _topViewHeight.constant = topConstH;
    _locViewHeight.constant = locConstH;
    _separatorHeight.constant = sepConstH;
    
    
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        if (curTextHeight > maxTextHeight) {
            self.textView.scrollEnabled = YES;
        } else {
            self.textView.scrollEnabled = NO;
        }
        [self sendFrameChangeFeedback];
    }];
}

-(void) setRightButtonTypeLocal {
    if ((_text == nil || _text.length == 0) && (_alternateKBImage || _alternateRightText)) {
        if (_alternateRightImage) {
            [_rightButton setTitle:nil forState:UIControlStateNormal];
            [_rightButton setTitle:nil forState:UIControlStateSelected];
            [_rightButton setImage:_alternateRightImage forState:UIControlStateNormal];
            [_rightButton setImage:_alternateKBImage forState:UIControlStateSelected];
            _rightButtonWidth.constant = [self getImageWidth:_alternateRightImage];
            
        } else if (_alternateRightText) {
            [_rightButton setTitle:_alternateRightText forState:UIControlStateNormal];
            [_rightButton setTitle:_alternateKBText forState:UIControlStateSelected];
            [_rightButton setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
            [_rightButton setTitleColor:self.buttonTextColor forState:UIControlStateDisabled];
            [_rightButton setImage:nil forState:UIControlStateNormal];
            [_rightButton setImage:nil forState:UIControlStateSelected];
            _rightButtonWidth.constant = [self getTextWidth:_alternateRightText];
        }
        
    } else {
        _rightButton.selected = NO;
        if (!_sendImage){
            [_rightButton setImage:nil forState:UIControlStateNormal];
            [_rightButton setTitle:[self sendTitle] forState:UIControlStateNormal];
            [_rightButton setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
            [_rightButton setTitleColor:self.buttonTextColor forState:UIControlStateDisabled];
            _rightButtonWidth.constant = [self getTextWidth:[self sendTitle]];
            
        } else {
            [_rightButton setTitle:nil forState:UIControlStateNormal];
            [_rightButton setImage:_sendImage forState:UIControlStateNormal];
            _rightButtonWidth.constant = [self getImageWidth:_sendImage];
        }
    }
}

-(void)sendFrameChangeFeedback {
    CGFloat height = MAX(44, topLineHeight + bottomLineHeight + topBottomGap + topBottomGap + _textViewHeight.constant + _topViewHeight.constant + _locViewHeight.constant + _separatorHeight.constant);
    [_delegate composeBarHeightDidChange:height];
}

- (CGFloat)textHeight {
    UITextView *textView = [self textView];
    CGSize size = [textView sizeThatFits:CGSizeMake([textView frame].size.width, FLT_MAX)];
    CGFloat height =  ceilf(size.height);
    if (height < 27) height = 27;
    return height;
}

-(CGFloat)maxHeight {
    if (_maxHeight > 44) {
        return _maxHeight;
    } else {
        return 44;
    }
}

-(void)textViewDidChange:(UITextView *)textView {
    self.text = [self textView].text;
    [self setRightButtonTypeLocal];
    [self adjustUIHeights];
    if ([_delegate respondsToSelector:@selector(composeBarTextDidChanged:)]){
        [_delegate composeBarTextDidChanged:_text];
    }
}

-(UIColor *)buttonTextColor {
    if (!_buttonTextColor) {
        _buttonTextColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:255/255.0 alpha:1.0];
    }
    return _buttonTextColor;
}

-(NSString *)sendTitle {
    if (!_sendTitle){
        _sendTitle = @"Send";
    }
    return _sendTitle;
}

-(UIColor *)getTopLineColor {
    if (!self.topLineColor){
        self.topLineColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    }
    return self.topLineColor;
}

-(UIColor *)getBottomLineColor {
    if (!self.bottomLineColor){
        self.bottomLineColor = [UIColor clearColor];
    }
    return self.bottomLineColor;
}

-(void)setTextBoxBorderColor:(UIColor *)textBoxBorderColor {
    if (!textBoxBorderColor) textBoxBorderColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _textBoxBorderColor = textBoxBorderColor;
    _textView.layer.borderColor = _textBoxBorderColor.CGColor;
}

#pragma mark UI Components
// Text box can other object containing view (eg. images) with be in this view
-(UIView *)contentView {
    if (!_contentView){
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.layer.cornerRadius = 5.0;
        _contentView.layer.masksToBounds = YES;
        _contentView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        _contentView.layer.borderWidth = 1.0;
        [self addSubview:_contentView];
    }
    
    return _contentView;
}

-(UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.layoutManager.allowsNonContiguousLayout = true;
        _textView.font = self.font;
        _textView.textContainerInset = UIEdgeInsetsMake(3.5, 3.0, 3.0, 3.0);
        _textView.delegate = self;
        [[self contentView] addSubview:_textView];
    }
    
    return _textView;
}

-(void)setPlaceholderView {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 250, 27)];
        _placeholderLabel.font = self.font;
        _placeholderLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [[self textView] addSubview:_placeholderLabel];
    }
}

-(UIView *)topView {
    if (!_topView){
        _topView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _topView.translatesAutoresizingMaskIntoConstraints = NO;
        [[self contentView] addSubview:_topView];
    }
    
    return _topView;
}

-(UIView *)locationView {
    if (!_locationView){
        _locationView = [[UIView alloc] initWithFrame:CGRectZero];
        _locationView.translatesAutoresizingMaskIntoConstraints = NO;
        _locationView.backgroundColor = [UIColor whiteColor];
        [[self contentView] addSubview:_locationView];
    }
    
    return _locationView;
}

-(UIView *)separator {
    if (!_separator){
        _separator = [[UIView alloc] initWithFrame:CGRectZero];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        _separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [[self contentView] addSubview:_separator];
    }
    
    return _separator;
}

-(UIView *)topLine {
    if (!_topLine){
        _topLine = [[UIView alloc] initWithFrame:CGRectZero];
        _topLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_topLine];
    }
    _topLine.backgroundColor = [self getTopLineColor];
    return _topLine;
}

-(UIView *)bottomLine {
    if (!_bottomLine){
        _bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bottomLine];
    }
    _bottomLine.backgroundColor = [self getBottomLineColor];
    return _bottomLine;
}

-(UIButton *)rightButton {
    if (!_rightButton){
        _rightButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _rightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_rightButton];
    }
    return _rightButton;
}

-(UIButton *)leftButton {
    if (!_leftButton){
        _leftButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_leftButton setImage:_leftButtonImage forState:UIControlStateNormal];
        [_leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_leftButton];
    }
    return _leftButton;
}

-(void)createTopItems {
    for (UIView *v in _topView.subviews){ [v removeFromSuperview]; }
    [_thumbUIs removeAllObjects];
    
    CGFloat x = 5.0;
    CGFloat w = (topHeight-10)*4/3;
    
    NSInteger itemCount = 0;
    if ([_dataSource respondsToSelector:@selector(numberOfItemsInComposeBar)]) {
        itemCount = [_dataSource numberOfItemsInComposeBar];
    }
    
    for (int i=0; i<itemCount; i++) {
        UIImage *image = nil;
        if ([_dataSource respondsToSelector:@selector(imageForComposeBarItemAtIndex:)]) {
            image = [_dataSource imageForComposeBarItemAtIndex:i];
        }
        NSAssert(image, @"image at index %d is nil", i);
        
        CGFloat length = topHeight-10;
        CGRect frame = CGRectMake(x, 5, length, length);
        UIView *thumb = [self createThumbnailWithImage:image tag:i frame:frame];
        x += w + 5;
        [_topView addSubview:thumb];
    }
    _topView.contentSize = CGSizeMake(x, topHeight);
    [self layoutIfNeeded];
}

-(void)createLocationItem {
    for (UIView *v in _locationView.subviews){ [v removeFromSuperview]; }
    _locationButton = nil;
    _locationClose = nil;
    
    NSString *locString = [_dataSource locationInComposeBar];
    if (locString) {
        
        _locationButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _locationButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_locationButton setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _locationButton.titleLabel.font = [UIFont italicSystemFontOfSize:14];
        _locationButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_locationButton.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_locationButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_locationButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [_locationButton addTarget:self action:@selector(locationClicked) forControlEvents:UIControlEventTouchUpInside];
        [_locationButton setTitle:locString forState:UIControlStateNormal];
        
        _locationClose = [[UIButton alloc] initWithFrame:CGRectZero];
        _locationClose.translatesAutoresizingMaskIntoConstraints = NO;
        [_locationClose setTitle:@"X" forState:UIControlStateNormal];
        _locationClose.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [_locationClose setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
        _locationClose.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _locationClose.layer.cornerRadius = 10;
        _locationClose.layer.masksToBounds = YES;
        [_locationClose addTarget:self action:@selector(removeLocation) forControlEvents:UIControlEventTouchUpInside];
        
        [_locationView addSubview:_locationButton];
        [_locationView addSubview:_locationClose];
        
        NSDictionary *dic = @{@"LOC": _locationButton, @"CLOSE": _locationClose};
        [_locationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4.0-[LOC][CLOSE]-4.0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:dic]];
        [_locationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[LOC]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:dic]];
        [_locationClose.heightAnchor constraintEqualToConstant:20.0].active = YES;
        [_locationClose.widthAnchor constraintEqualToConstant:20.0].active = YES;
    }
    [self layoutIfNeeded];
}

-(UIView *)createThumbnailWithImage:(UIImage *)image tag:(NSInteger)tag frame:(CGRect)frame {
    UIView *thumb = [[UIView alloc] initWithFrame:frame];
    thumb.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:thumb.bounds];
    imageView.image = image;
    imageView.layer.cornerRadius = frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [thumb addSubview:imageView];
    
    UIButton *select = [[UIButton alloc] initWithFrame:thumb.bounds];
    select.tag = tag;
    [select addTarget:self action:@selector(selectThumb:) forControlEvents:UIControlEventTouchUpInside];
    [thumb addSubview:select];
    
    UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 22, -3, 25, 25)];
    [close setTitle:@"X" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [close setTitleColor:[UIColor colorWithWhite:0.5 alpha:1.0] forState:UIControlStateNormal];
    close.tag = tag;
    close.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    close.layer.cornerRadius = 15.0;
    close.layer.masksToBounds = YES;
    [close addTarget:self action:@selector(closeThumb:) forControlEvents:UIControlEventTouchUpInside];
    [thumb addSubview:close];
    
    [_thumbUIs addObject:close];
    [_thumbUIs addObject:thumb];
    
    return thumb;
}

-(CGFloat)getImageWidth:(UIImage *)img {
    if (img) {
        CGSize size = img.size;
        CGFloat width = 52;
        if (size.height < 44) width = size.width + 16;
        else {
            width = 44 * size.height / size.width + 16;
        }
        if (width > 100) width = 100;
        return width;
    }
    return 16;
}

-(CGFloat)getTextWidth:(NSString *)text {
    if (text) {
        return [text boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17]} context:nil].size.width + 16;
    }
    return 16;
}

-(void)locationClicked {
    if([_delegate respondsToSelector:@selector(composeBarLocationSelected)]){
        [_delegate composeBarLocationSelected];
    }
}

-(void)removeLocation {
    if (!_disableInput){
        if ([_delegate respondsToSelector:@selector(deleteComposeBarLocation)]) {
            [_delegate deleteComposeBarLocation];
            [self reloadComposeBar];
        }
    }
}

-(void)selectThumb:(UIButton *)btn {
    if ([_delegate respondsToSelector:@selector(selecteComposeBarItemAtIndex:)]) {
        [_delegate selecteComposeBarItemAtIndex:btn.tag];
    }
}

-(void)closeThumb:(UIButton *)btn {
    if (!_disableInput){
        if ([_delegate respondsToSelector:@selector(deleteComposeBarItemAtIndex:)]) {
            [_delegate deleteComposeBarItemAtIndex:btn.tag];
            [self reloadComposeBar];
        }
    }
}

@end