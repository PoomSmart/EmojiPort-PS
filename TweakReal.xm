#import <substrate.h>
#import <EmojiLibrary/PSEmojiUtilities.h>
#import <UIKit/UIKBScreenTraits.h>
#import <UIKit/UIKBTree.h>
#import <theos/IOSMacros.h>
#import <version.h>

BOOL iOS91Up;

%hook UIKeyboardEmojiCategory

+ (NSInteger)numberOfCategories {
    return CATEGORIES_COUNT;
}

+ (UIKeyboardEmojiCategory *)categoryForType:(PSEmojiCategory)categoryType {
    NSArray <UIKeyboardEmojiCategory *> *categories = [self categories];
    UIKeyboardEmojiCategory *categoryForType = categories[categoryType];
    NSArray <UIKeyboardEmoji *> *emojiForType = categoryForType.emoji;
    if (emojiForType.count)
        return categoryForType;
    NSArray <NSString *> *emojiArray = nil;
    switch (categoryType) {
        case PSEmojiCategoryPrepopulated:
        case PSEmojiCategoryRecent: {
            NSMutableArray <UIKeyboardEmoji *> *recents = [self emojiRecentsFromPreferences];
            if (recents) {
                categoryForType.emoji = recents;
                return categoryForType;
            }
            break;
        }
        case PSEmojiCategoryPeople:
            emojiArray = [PSEmojiUtilities PeopleEmoji];
            break;
        case PSEmojiCategoryNature:
            emojiArray = [PSEmojiUtilities NatureEmoji];
            break;
        case PSEmojiCategoryFoodAndDrink:
            emojiArray = [PSEmojiUtilities FoodAndDrinkEmoji];
            break;
        case PSEmojiCategoryObjects:
        case IDXPSEmojiCategoryObjects: // == PSEmojiCategoryTravelAndPlaces
            if (!iOS91Up || (categoryType == PSEmojiCategoryObjects && iOS91Up)) {
                emojiArray = [PSEmojiUtilities ObjectsEmoji];
                break;
            }
        case IDXPSEmojiCategoryTravelAndPlaces: // == PSEmojiCategoryActivity
            if (!iOS91Up || (categoryType == PSEmojiCategoryTravelAndPlaces && iOS91Up)) {
                emojiArray = [PSEmojiUtilities TravelAndPlacesEmoji];
                break;
            }
        case IDXPSEmojiCategoryActivity:
            emojiArray = [PSEmojiUtilities ActivityEmoji];
            break;
        case PSEmojiCategorySymbols:
        case PSEmojiCategoryFlags:
            if (!iOS91Up || (categoryType == PSEmojiCategorySymbols && iOS91Up)) {
                emojiArray = [PSEmojiUtilities SymbolsEmoji];
                break;
            }
        case IDXPSEmojiCategoryFlags:
            emojiArray = [PSEmojiUtilities FlagsEmoji];
            break;
    }
    if (emojiArray) {
        NSMutableArray <UIKeyboardEmoji *> *_emojiArray = [NSMutableArray arrayWithCapacity:emojiArray.count];
        for (NSString *emojiString in emojiArray)
            [PSEmojiUtilities addEmoji:_emojiArray emojiString:emojiString withVariantMask:[PSEmojiUtilities hasVariantsForEmoji:emojiString]];
        categoryForType.emoji = _emojiArray;
    }
    return categoryForType;
}

+ (NSUInteger)hasVariantsForEmoji:(NSString *)emoji {
    return [PSEmojiUtilities hasVariantsForEmoji:emoji];
}

%end

%hook UIKeyboardEmojiCollectionViewCell

- (void)setEmojiFontSize:(NSInteger)fontSize {
    if (fontSize != self.emojiFontSize)
        %orig;
}

%end

%hook UIKeyboardEmojiCollectionInputView

- (UIKeyboardEmojiCollectionViewCell *)collectionView:(UICollectionView *)collectionView_ cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [PSEmojiUtilities collectionView:collectionView_ cellForItemAtIndexPath:indexPath inputView:self];
}

- (NSString *)emojiBaseUnicodeString:(NSString *)string {
    return [PSEmojiUtilities emojiBaseString:string];
}

%end

%group iOS8

%hook UIKeyboardEmojiGraphicsTraits

- (id)initWithScreenTrait:(UIKBScreenTraits *)trait {
    self = %orig;
    CGFloat keyboardWidth = trait.keyboardWidth;
    if (keyboardWidth >= 1024.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 44.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 11.0;
        MSHookIvar<CGFloat>(self, "_categoryHeaderHeight") = 44.0;
        MSHookIvar<CGFloat>(self, "_inputViewLeftMostPadding") = 24.0;
        MSHookIvar<CGFloat>(self, "_inputViewRightMostPadding") = 35.0;
        MSHookIvar<CGFloat>(self, "_minimumInteritemSpacing") = 10.0;
        MSHookIvar<CGFloat>(self, "_minimumLineSpacing") = 15.0;
        MSHookIvar<CGFloat>(self, "_columnOffset") = 15.0;
        MSHookIvar<CGFloat>(self, "_sectionOffset") = 45.0;
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 6.0;
        MSHookIvar<CGSize>(self, "_fakeEmojiKeySize") = CGSizeMake(64.0, 64.0);
    } else if (keyboardWidth >= 768.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 4.0;
    } else if (keyboardWidth >= 736.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 34.0 / 3.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 30.0;
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 5.0;
    } else if (keyboardWidth >= 667.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 32.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 7.0;
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 10.0;
    } else if (keyboardWidth >= 568.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 8.5;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 25.0;
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 3.0;
        MSHookIvar<CGSize>(self, "_fakeEmojiKeySize") = CGSizeMake(42.0, 33.0);
    } else if (keyboardWidth >= 414.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 30.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 5.0 / 3.0 - 0.5;
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 10.0;
        MSHookIvar<CGSize>(self, "_fakeEmojiKeySize") = CGSizeMake(40.0, 46.0);
    } else if (keyboardWidth >= 375.0) {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 30.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = 0; // 0.5
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 1.0;
        MSHookIvar<CGSize>(self, "_fakeEmojiKeySize") = CGSizeMake(38.0, 44.0);
    } else {
        MSHookIvar<CGFloat>(self, "_categorySelectedCirWidth") = 25.0;
        MSHookIvar<CGFloat>(self, "_categorySelectedCirPadding") = -0.5; // 0
        MSHookIvar<CGFloat>(self, "_scrubViewTopPadding") = 7.5;
        MSHookIvar<CGSize>(self, "_fakeEmojiKeySize") = CGSizeMake(38.0, 42.0);
    }
    return self;
}

%end

%hook UIKeyboardEmojiSplitCategoryPicker

- (NSString *)titleForRow:(NSInteger)row {
    return [%c(UIKeyboardEmojiCategory) displayName:row];
}

%end

%end

%ctor {
    iOS91Up = IS_IOS_OR_NEWER(iOS_9_1);
    %init;
    if (!IS_IOS_OR_NEWER(iOS_9_0)) {
        %init(iOS8);
    }
}