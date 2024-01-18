#import <EmojiLibrary/PSEmojiUtilities.h>
#import <UIKit/UIKBTree.h>
#import <theos/IOSMacros.h>

BOOL overrideNewVariant = NO;

%hook UIKeyboardEmojiCollectionInputView

- (UIKBTree *)subTreeHitTest:(CGPoint)point {
    overrideNewVariant = YES;
    BOOL hackVariant = NO;
    BOOL inside = [self pointInside:point forEvent:NULL];
    UIKeyboardEmojiCollectionViewCell *cell = nil;
    if (inside) {
        UIKeyboardEmojiCollectionView *collectionView = [self valueForKey:@"_collectionView"];
        CGPoint target = [collectionView convertPoint:point fromView:self];
        cell = [collectionView closestCellForPoint:target];
        hackVariant = cell && [PSEmojiUtilities isCoupleMultiSkinToneEmoji:cell.emoji.emojiString];
    }
    if (hackVariant)
        cell.emoji.variantMask = 2;
    UIKBTree *tree = %orig;
    overrideNewVariant = NO;
    NSString *emojiString = tree.representedString;
    NSMutableArray <NSString *> *variants = [PSEmojiUtilities skinToneVariants:emojiString];
    if (variants) {
        if (hackVariant) {
            if (IS_IPAD) {
                for (int i = 20; i > 0; i -= 5)
                    [variants insertObject:@"" atIndex:i];
                [variants insertObject:emojiString atIndex:0];
                NSMutableArray *trueVariants = [NSMutableArray array];
                for (NSInteger index = 0; index < 30; ++index) {
                    NSInteger insertIndex = ((index % 5) * 6) + (index / 5);
                    [trueVariants addObject:variants[insertIndex]];
                }
                variants = trueVariants;
            }
        } else {
            NSString *baseString = [PSEmojiUtilities emojiBaseString:emojiString];
            [variants insertObject:baseString atIndex:0];
        }
        [tree.subtrees removeAllObjects];
        for (NSString *variant in variants) {
            UIKBTree *subtree = [%c(UIKBTree) treeOfType:8];
            subtree.representedString = variant;
            subtree.displayString = variant;
            subtree.displayType = 0;
            subtree.name = [NSString stringWithFormat:@"%@/%@", tree.name, subtree.displayString];
            subtree.overrideDisplayString = nil;
            [tree.subtrees addObject:subtree];
        }
    }
    if (hackVariant)
        cell.emoji.variantMask = 0;
    return tree;
}

%end

%hook UIKBTree

- (void)setRepresentedString:(NSString *)string {
    %orig(overrideNewVariant ? [PSEmojiUtilities overrideKBTreeEmoji:string] : string);
}

%end

%hook UIKBRenderFactory

- (void)modifyTraitsForDividerVariant:(id)variant withKey:(UIKBTree *)key {
    if ([PSEmojiUtilities isCoupleMultiSkinToneEmoji:key.displayString])
        return;
    %orig;
}

%end

%hook UIKBRenderFactoryiPad

- (NSInteger)rowLimitForKey:(UIKBTree *)tree {
    if ([tree.name isEqualToString:@"EmojiPopupKey"] && [PSEmojiUtilities isCoupleMultiSkinToneEmoji:tree.displayString])
        return 6;
    return %orig;
}

%end

%hook UIKBRenderFactoryiPhone

- (void)_configureTraitsForPopupStyle:(id)style withKey:(UIKBTree *)key onKeyplane:(id)keyplane {
    BOOL isEmoji = [key.name isEqualToString:@"EmojiPopupKey"] && [PSEmojiUtilities isCoupleMultiSkinToneEmoji:key.displayString];
    if (isEmoji)
        key.name = @"EmojiPopupKey2";
    %orig(style, key, keyplane);
    if (isEmoji)
        key.name = @"EmojiPopupKey";
}

%end
