#import "../EmojiLibrary/PSEmojiUtilities.h"
#import <UIKit/UIKBTree.h>

@interface UIKeyboardEmojiCollectionInputView (Hack)
- (BOOL)pointInside:(CGPoint)point forEvent:(void *)event;
@end

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
    NSMutableArray *variants = [PSEmojiUtilities coupleSkinToneVariants:emojiString];
    if (variants) {
        if (IS_IPAD) {
            for (int i = 20; i > 0; i -= 5)
                [variants insertObject:@"" atIndex:i];
            NSMutableArray *trueVariants = [NSMutableArray array];
            for (NSInteger index = 0; index < 30; ++index) {
                NSInteger insertIndex = ((index % 5) * 6) + (index / 5);
                [trueVariants addObject:variants[insertIndex]];
            }
            variants = trueVariants;
        }
        [variants insertObject:emojiString atIndex:0];
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