#define CHECK_TARGET
#define NEW_EMOJI_WORKAROUND
#import "../PS.h"
#import "../EmojiLibrary/Emoji10.h"
#import "../EmojiLibrary/Header.h"
#import "../EmojiLibrary/Functions.x"

BOOL iOS91Up;

%hook UIKeyboardEmojiCategory

+ (UIKeyboardEmojiCategory *)categoryForType: (NSInteger)categoryType {
    if (!iOS91Up && categoryType >= CATEGORIES_COUNT)
        return %orig;
    NSArray *categories = [self categories];
    UIKeyboardEmojiCategory *categoryForType = categories[categoryType];
    NSArray *emojiForType = categoryForType.emoji;
    if (emojiForType.count)
        return categoryForType;
    NSArray *emojiArray = PrepolulatedEmoji;
    switch (categoryType) {
        case 0: {
            NSMutableArray *recents = [self emojiRecentsFromPreferences];
            if (recents) {
                categoryForType.emoji = recents;
                return categoryForType;
            }
            break;
        }
        case 1:
            emojiArray = PeopleEmoji;
            break;
        case 2:
            emojiArray = NatureEmoji;
            break;
        case 3:
            emojiArray = FoodAndDrinkEmoji;
            break;
        case 10:
        case 6:
            if (!iOS91Up || (categoryType == 10 && iOS91Up)) {
                emojiArray = ObjectsEmoji;
                break;
            }
        case 5:
            if (!iOS91Up || (categoryType == 6 && iOS91Up)) {
                emojiArray = TravelAndPlacesEmoji;
                break;
            }
        case 4:
            emojiArray = ActivityEmoji;
            break;
        case 11:
        case 7:
            if (!iOS91Up || (categoryType == 11 && iOS91Up)) {
                emojiArray = SymbolsEmoji;
                break;
            }
        case 8:
            emojiArray = FlagsEmoji;
            break;
    }
    NSMutableArray *_emojiArray = [NSMutableArray arrayWithCapacity:emojiArray.count];
    for (NSString *emoji in emojiArray)
        addEmoji(_emojiArray, emoji, [[self class] hasVariantsForEmoji:emoji]);
    categoryForType.emoji = _emojiArray;
    return categoryForType;
}

+ (NSUInteger)hasVariantsForEmoji:(NSString *)emoji {
    return hasVariantsForEmoji(emoji);
}

%end

%group preiOS91

%hook UIKeyboardEmojiCategory

+ (NSInteger)numberOfCategories {
    return CATEGORIES_COUNT;
}

%end

%end

%hook UIKeyboardEmojiCollectionInputView

- (UIKeyboardEmojiCollectionViewCell *)collectionView: (UICollectionView *)collectionView_ cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    UIKeyboardEmojiCollectionView *collectionView(MSHookIvar<UIKeyboardEmojiCollectionView *>(self, "_collectionView"));
    UIKeyboardEmojiCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"kEmojiCellIdentifier" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        NSArray *recents = collectionView.inputController.recents;
        NSArray *prepolulatedEmojis = ((UIKeyboardEmojiCategory *)[NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:9]).emoji;
        NSUInteger prepolulatedCount = [MSHookIvar<UIKeyboardEmojiGraphicsTraits *>(self, "_emojiGraphicsTraits")prepolulatedRecentCount];
        NSRange range = NSMakeRange(0, prepolulatedCount);
        if (recents.count) {
            NSUInteger idx = 0;
            NSMutableArray *array = [NSMutableArray arrayWithArray:recents];
            if (array.count < prepolulatedCount) {
                while (idx < prepolulatedEmojis.count && prepolulatedCount != array.count)
                    [array addObject:prepolulatedEmojis[idx++]];
            }
            cell.emoji = [array subarrayWithRange:range][indexPath.item];
        } else
            cell.emoji = [prepolulatedEmojis subarrayWithRange:range][indexPath.item];
    } else {
        NSInteger section = indexPath.section;
        if (iOS91Up)
            section = [NSClassFromString(@"UIKeyboardEmojiCategory") categoryTypeForCategoryIndex:section];
        UIKeyboardEmojiCategory *category = [NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:section];
        NSArray <UIKeyboardEmoji *> *emojis = category.emoji;
        cell.emoji = emojis[indexPath.item];
        if (section <= 1 || section == 4) {
            NSMutableDictionary *skinPrefs = [collectionView.inputController skinToneBaseKeyPreferences];
            if (skinPrefs && cell.emoji.variantMask == 2) {
                NSString *baseString = emojiBaseString(cell.emoji.emojiString);
                NSString *skinned = skinPrefs[baseString];
                if (skinned) {
                    cell.emoji.emojiString = skinned;
                    cell.emoji = cell.emoji;
                }
            }
        }
    }
    cell.emojiFontSize = [collectionView emojiGraphicsTraits].emojiKeyWidth;
    return cell;
}

- (NSString *)emojiBaseUnicodeString:(NSString *)string {
    return emojiBaseString(string);
}

BOOL overrideNewVariant = NO;

- (id)subTreeHitTest:(CGPoint)point {
    overrideNewVariant = YES;
    id r = %orig;
    overrideNewVariant = NO;
    return r;
}

%end

%hook UIKBTree

- (void)setRepresentedString: (NSString *)string {
    %orig(overrideKBTreeEmoji(string, overrideNewVariant));
}

%end

%ctor {
    if (isTarget(TargetTypeGUINoExtension)) {
        iOS91Up = isiOS91Up;
        #if TARGET_OS_SIMULATOR
        dlopen("/opt/simject/EmojiAttributes.dylib", RTLD_LAZY);
        if (!iOS91Up)
            dlopen("/opt/simject/EmojiLocalization.dylib", RTLD_LAZY);
        #else
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiAttributesRun.dylib", RTLD_LAZY);
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiLocalization.dylib", RTLD_LAZY);
        #endif
        %init;
        if (!iOS91Up) {
            %init(preiOS91);
        }
    }
}
