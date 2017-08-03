#import "../PS.h"
#import "../EmojiLibrary/PSEmojiUtilities.h"

BOOL iOS91Up;

%hook UIKeyboardEmojiCategory

+ (UIKeyboardEmojiCategory *)categoryForType: (NSInteger)categoryType {
    if (!iOS91Up && categoryType >= CATEGORIES_COUNT)
        return %orig;
    NSArray <UIKeyboardEmojiCategory *> *categories = [self categories];
    UIKeyboardEmojiCategory *categoryForType = categories[categoryType];
    NSArray <UIKeyboardEmoji *> *emojiForType = categoryForType.emoji;
    if (emojiForType.count)
        return categoryForType;
    NSArray <NSString *> *emojiArray = [PSEmojiUtilities PrepolulatedEmoji];
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
            emojiArray = [PSEmojiUtilities PeopleEmoji];
            break;
        case 2:
            emojiArray = [PSEmojiUtilities NatureEmoji];
            break;
        case 3:
            emojiArray = [PSEmojiUtilities FoodAndDrinkEmoji];
            break;
        case 10:
        case 6:
            if (!iOS91Up || (categoryType == 10 && iOS91Up)) {
                emojiArray = [PSEmojiUtilities ObjectsEmoji];
                break;
            }
        case 5:
            if (!iOS91Up || (categoryType == 6 && iOS91Up)) {
                emojiArray = [PSEmojiUtilities TravelAndPlacesEmoji];
                break;
            }
        case 4:
            emojiArray = [PSEmojiUtilities ActivityEmoji];
            break;
        case 11:
        case 7:
            if (!iOS91Up || (categoryType == 11 && iOS91Up)) {
                emojiArray = [PSEmojiUtilities SymbolsEmoji];
                break;
            }
        case 8:
            emojiArray = [PSEmojiUtilities FlagsEmoji];
            break;
    }
    NSMutableArray <UIKeyboardEmoji *> *_emojiArray = [NSMutableArray arrayWithCapacity:emojiArray.count];
    for (NSString *emojiString in emojiArray)
        [PSEmojiUtilities addEmoji:_emojiArray emojiString:emojiString withVariantMask:[PSEmojiUtilities hasVariantsForEmoji:emojiString]];
    categoryForType.emoji = _emojiArray;
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

%hook UIKeyboardEmojiCollectionInputView

- (UIKeyboardEmojiCollectionViewCell *)collectionView: (UICollectionView *)collectionView_ cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    UIKeyboardEmojiCollectionView *collectionView(MSHookIvar<UIKeyboardEmojiCollectionView *>(self, "_collectionView"));
    UIKeyboardEmojiCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"kEmojiCellIdentifier" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        NSArray <UIKeyboardEmoji *> *recents = collectionView.inputController.recents;
        NSArray <UIKeyboardEmoji *> *prepolulatedEmojis = ((UIKeyboardEmojiCategory *)[NSClassFromString(@"UIKeyboardEmojiCategory") categoryForType:9]).emoji;
        NSUInteger prepolulatedCount = [MSHookIvar<UIKeyboardEmojiGraphicsTraits *>(self, "_emojiGraphicsTraits")prepolulatedRecentCount];
        NSRange range = NSMakeRange(0, prepolulatedCount);
        if (recents.count) {
            NSUInteger idx = 0;
            NSMutableArray <UIKeyboardEmoji *> *array = [NSMutableArray arrayWithArray:recents];
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
        if ([PSEmojiUtilities sectionHasSkin:section]) {
            NSMutableDictionary <NSString *, NSString *> *skinPrefs = [collectionView.inputController skinToneBaseKeyPreferences];
            if (skinPrefs && cell.emoji.variantMask & PSEmojiTypeSkin) {
                NSString *skinned = skinPrefs[[PSEmojiUtilities emojiBaseString:cell.emoji.emojiString]];
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
    return [PSEmojiUtilities emojiBaseString:string];
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
    %orig([PSEmojiUtilities overrideKBTreeEmoji:string overrideNewVariant:overrideNewVariant]);
}

%end

%ctor {
    iOS91Up = isiOS91Up;
#if TARGET_OS_SIMULATOR
    dlopen("/opt/simject/EmojiAttributes.dylib", RTLD_LAZY);
    if (!iOS91Up)
        dlopen("/opt/simject/EmojiLocalization.dylib", RTLD_LAZY);
#endif
    %init;
    if (!iOS91Up) {
        %init(preiOS91);
    }
}
