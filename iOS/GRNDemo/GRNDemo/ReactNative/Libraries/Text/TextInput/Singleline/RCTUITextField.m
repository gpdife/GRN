/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTUITextField.h"

#import <React/RCTUtils.h>
#import <React/UIView+React.h>

#import "RCTBackedTextInputDelegateAdapter.h"

@implementation RCTUITextField {
  RCTBackedTextFieldDelegateAdapter *_textInputDelegateAdapter;
  NSMutableAttributedString *_attributesHolder;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_textDidChange)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self];

    _textInputDelegateAdapter = [[RCTBackedTextFieldDelegateAdapter alloc] initWithTextField:self];
    _attributesHolder = [[NSMutableAttributedString alloc] init];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_textDidChange
{
  _textWasPasted = NO;
}

#pragma mark - Properties

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
  _textContainerInset = textContainerInset;
  [self setNeedsLayout];
}

- (void)setPlaceholder:(NSString *)placeholder
{
  [super setPlaceholder:placeholder];
  [self _updatePlaceholder];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
  _placeholderColor = placeholderColor;
  [self _updatePlaceholder];
}

- (void)_updatePlaceholder
{
  if (self.placeholder == nil) {
    return;
  }

  NSMutableDictionary *attributes = [NSMutableDictionary new];
  if (_placeholderColor) {
    [attributes setObject:_placeholderColor forKey:NSForegroundColorAttributeName];
  }

  self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder
                                                               attributes:attributes];
}

- (BOOL)isEditable
{
  return self.isEnabled;
}

- (void)setEditable:(BOOL)editable
{
  self.enabled = editable;
}

- (void)setScrollEnabled:(BOOL)enabled
{
  // Do noting, compatible with multiline textinput
}

- (BOOL)scrollEnabled
{
  return NO;
}

#pragma mark - Context Menu

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (_contextMenuHidden) {
    return NO;
  }

  return [super canPerformAction:action withSender:sender];
}

#pragma mark - Caret Manipulation

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
  if (_caretHidden) {
    return CGRectZero;
  }

  return [super caretRectForPosition:position];
}

#pragma mark - Fix for CJK Languages

/* 
 * The workaround to fix inputting complex locales (like CJK languages).
 * When we use `setAttrbutedText:` while user is inputting text in a complex
 * locale (like Chinese, Japanese or Korean), some internal state breaks and
 * input stops working.
 *
 * To workaround that, we don't skip underlying attributedString in the text
 * field if only attributes were changed. We keep track of these attributes in
 * a local variable.
 *
 * There are two methods that are altered by this workaround:
 *
 * (1) `-setAttributedText:` 
 *     Applies the attributed string change to a local variable `_attributesHolder` instead of calling `-[super setAttributedText:]`.
 *     If new attributed text differs from the existing one only in attributes,
 *     skips `-[super setAttributedText:`] completely.
 *
 * (2) `-attributedText` 
 *     Return `_attributesHolder` context.
 *     Updates `_atributesHolder` before returning if the underlying `super.attributedText.string` was changed.
 *
 */
- (void)setAttributedText:(NSAttributedString *)attributedText
{
  BOOL textWasChanged = ![_attributesHolder.string isEqualToString:attributedText.string];
  [_attributesHolder setAttributedString:attributedText];

  if (textWasChanged) {
    [super setAttributedText:attributedText];
  }
}

- (NSAttributedString *)attributedText
{
  if (![super.attributedText.string isEqualToString:_attributesHolder.string]) {
    [_attributesHolder setAttributedString:super.attributedText];
  }

  return _attributesHolder;
}

#pragma mark - Positioning Overrides

- (CGRect)textRectForBounds:(CGRect)bounds
{
  return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], _textContainerInset);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
  return [self textRectForBounds:bounds];
}

#pragma mark - Overrides

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  if (!notifyDelegate) {
    // We have to notify an adapter that following selection change was initiated programmatically,
    // so the adapter must not generate a notification for it.
    [_textInputDelegateAdapter skipNextTextInputDidChangeSelectionEventWithTextRange:selectedTextRange];
  }

  [super setSelectedTextRange:selectedTextRange];
}

- (void)paste:(id)sender
{
  [super paste:sender];
  _textWasPasted = YES;
}

#pragma mark - Layout

- (CGSize)contentSize
{
  // Returning size DOES contain `textContainerInset` (aka `padding`).
  return self.intrinsicContentSize;
}

- (CGSize)intrinsicContentSize
{
  // Note: `placeholder` defines intrinsic size for `<TextInput>`.
  NSString *text = self.placeholder ?: @"";
  CGSize size = [text sizeWithAttributes:@{NSFontAttributeName: self.font}];
  size = CGSizeMake(RCTCeilPixelValue(size.width), RCTCeilPixelValue(size.height));
  size.width += _textContainerInset.left + _textContainerInset.right;
  size.height += _textContainerInset.top + _textContainerInset.bottom;
  // Returning size DOES contain `textContainerInset` (aka `padding`).
  return size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
  // All size values here contain `textContainerInset` (aka `padding`).
  CGSize intrinsicSize = self.intrinsicContentSize;
  return CGSizeMake(MIN(size.width, intrinsicSize.width), MIN(size.height, intrinsicSize.height));
}

@end
