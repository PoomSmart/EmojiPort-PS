#import "../PSHeader/iOSVersions.h"
#import "../EmojiLibrary/PSEmojiUtilities.h"
#import <theos/IOSMacros.h>

BOOL iOS91Up;

%hook UIKeyboardEmojiCategory

+ (UIKeyboardEmojiCategory *)categoryForType:(PSEmojiCategory)categoryType {
    if (!iOS91Up && categoryType >= CATEGORIES_COUNT)
        return %orig;
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

%group preiOS91

%hook UIKeyboardEmojiCategory

+ (NSInteger)numberOfCategories {
    return CATEGORIES_COUNT;
}

%end

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

%ctor {
    iOS91Up = IS_IOS_OR_NEWER(iOS_9_1);
    %init;
    if (!iOS91Up) {
        %init(preiOS91);
    }
}