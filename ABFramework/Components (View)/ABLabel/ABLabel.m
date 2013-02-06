//
//  ABLabel.m
//  ABFramework
//
//  Created by Alexander Blunck on 2/6/13.
//  Copyright (c) 2013 Ablfx. All rights reserved.
//

#import "ABLabel.h"

@interface ABLabel () {
    UITextField *_textField;
    UILabel *_label;
}
@end

@implementation ABLabel

#pragma mark - Initializer
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //TextField
        _textField = [[UITextField alloc] initWithFrame:self.bounds];
        _textField.backgroundColor = [UIColor clearColor];
        _textField.userInteractionEnabled = NO;
        [self addSubview:_textField];
        
        //Label (not used by default)
        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.backgroundColor = [UIColor clearColor];
        _label.numberOfLines = 0;
        _label.alpha = 0.0f;
        [self addSubview:_label];
        
        //Configuration
        self.fontName = @"HelveticaNeue";
        self.textSize = 15.0f;
        self.textColor = [UIColor blackColor];
        self.trimAutomatically = YES;
        self.lineBreakEnabled = NO;
        self.shadow = ABLabelShadowNone;
        self.shadowColor = nil;
        self.centeredHorizontally = YES;
        self.centeredVertically = YES;
    }
    return self;
}

-(id) init
{
    return [self initWithFrame:CGRectZero];
}



#pragma mark - Change
-(void) trim
{
    //Label
    if (_lineBreakEnabled) {
        [_label sizeToFit];
        self.frame = CGRectChangingCGSize(self.frame, _label.bounds.size);
    }
    //TextField
    else
    {
        [_textField sizeToFit];
        self.frame = CGRectChangingCGSize(self.frame, _textField.bounds.size);
    }
}



#pragma mark - Accessors
//name
-(void) setText:(NSString *)text
{
    _text = text;
    
    _textField.text = _text;
    _label.text = _text;
    
    //If own frame size is not set automatically trim label (or always if trimAutomatically is enabled)
    if (self.trimAutomatically || self.bounds.size.width == 0.0f || self.bounds.size.height == 0.0f)
    {
        [self trim];
    }
}

//fontName
-(void) setFontName:(NSString *)fontName
{
    _fontName = fontName;
    
    _textField.font = [UIFont fontWithName:_fontName size:self.textSize];
    _label.font = [UIFont fontWithName:_fontName size:self.textSize];
    
    if (self.trimAutomatically) [self trim];
}

//textSize
-(void) setTextSize:(CGFloat)textSize
{
    _textSize = textSize;
    _textField.font = [UIFont fontWithName:self.fontName size:_textSize];
    _label.font = [UIFont fontWithName:self.fontName size:_textSize];
    
    if (self.trimAutomatically) [self trim];
}

//textColor
-(void) setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _textField.textColor = _textColor;
    _label.textColor = _textColor;
}

-(void) setLineBreakEnabled:(BOOL)lineBreakEnabled
{
    _lineBreakEnabled = lineBreakEnabled;
    
    //Turn of automatic trimming if enabled
    self.trimAutomatically = (_lineBreakEnabled) ? NO : YES;
    
    //Assume left text alignment if enabled
    self.centeredHorizontally = (_lineBreakEnabled) ? NO : YES;
    
    //Hide TextField & Show Label if enabled
    _textField.alpha = (_lineBreakEnabled) ? 0.0f : 1.0f;
    _label.alpha = (_lineBreakEnabled) ? 1.0f :0.0f;

}

//shadow
-(void) setShadow:(ABLabelShadow)shadow
{
    _shadow = shadow;
    
    UIColor *shadowColor = nil;
    CGSize shadowOffset = {0.0f, 0.0f};
    CGFloat shadowRadius = 0.0f;
    CGFloat shadowOpactiy = 0.0f;
    
    if (_shadow == ABLabelShadowNone)
    {
        shadowOpactiy = 0.0f;
    }
    else if (shadow == ABLabelShadowHard)
    {
        shadowColor = [UIColor blackColor];
        shadowOffset = CGSizeMake(0.0f, 1.0f);
        shadowRadius = 0.0f;
        shadowOpactiy = 1.0f;

    }
    else if (_shadow == ABLabelShadowLetterpress)
    {
        shadowColor = [UIColor whiteColor];
        shadowOffset = CGSizeMake(1.0f, 1.0f);
        shadowRadius = 0.0f;
        shadowOpactiy = 1.0f;
    }
    else if (_shadow == ABLabelShadowSoft)
    {
        shadowColor = [UIColor blackColor];
        shadowOffset = CGSizeMake(0.0f, 0.0f);
        shadowRadius = 5.0f;
        shadowOpactiy = 1.0f;
    }
    
    _textField.layer.shadowColor = [shadowColor CGColor];
    _textField.layer.shadowOffset = shadowOffset;
    _textField.layer.shadowRadius = shadowRadius;
    _textField.layer.shadowOpacity = shadowOpactiy;
    
    _label.shadowColor = shadowColor;
    _label.shadowOffset = shadowOffset;
    
    if (self.trimAutomatically) [self trim];
}

//shadowColor
-(void) setShadowColor:(UIColor *)shadowColor
{
    _shadowColor = shadowColor;
    _textField.layer.shadowColor = [_shadowColor CGColor];
    _label.shadowColor = _shadowColor;
}

//centeredHorizontally
-(void) setCenteredHorizontally:(BOOL)centeredHorizontally
{
    _centeredHorizontally = centeredHorizontally;
    
    NSTextAlignment alignment = (_centeredHorizontally) ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    
    _textField.textAlignment = alignment;
    _label.textAlignment = alignment;
    
    if (self.trimAutomatically) [self trim];
}

//centeredVertically
-(void) setCenteredVertically:(BOOL)centeredVertically
{
    _centeredVertically = centeredVertically;
    _textField.contentVerticalAlignment = (_centeredVertically) ? UIControlContentVerticalAlignmentCenter : UIControlContentVerticalAlignmentTop;
    
    if (self.trimAutomatically) [self trim];
}

-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _textField.frame = CGRectChangingCGSize(_textField.frame, frame.size);
    _label.frame = CGRectChangingCGSize(_label.frame, frame.size);
}

@end