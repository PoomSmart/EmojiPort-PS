#import "../EmojiLibrary/PSEmojiUtilities.h"
#import <UIKit/UIKBTree.h>

BOOL overrideNewVariant = NO;

%hook UIKeyboardEmojiCollectionInputView

- (UIKBTree *)subTreeHitTest:(CGPoint)point {
    overrideNewVariant = YES;
    UIKBTree *tree = %orig;
    overrideNewVariant = NO;
    NSString *emojiString = tree.representedString;
    NSUInteger type = [[PSEmojiUtilities CoupleMultiSkinToneEmoji] indexOfObject:emojiString];
    if (type != NSNotFound) {
        NSMutableArray *variants = [NSMutableArray array];
        BOOL first = YES;
        BOOL ipad = IS_IPAD;
        for (NSString *leftSkin in [PSEmojiUtilities skinModifiers]) {
            if (first || ipad)
                [variants addObject:first ? emojiString : @""];
            first = NO;
            for (NSString *rightSkin in [PSEmojiUtilities skinModifiers]) {
                switch (type) {
                    case 0:
                        [variants addObject:[NSString stringWithFormat:@"👩%@‍🤝‍👩%@", leftSkin, rightSkin]];
                        break;
                    case 1:
                        [variants addObject:[NSString stringWithFormat:@"👨%@‍🤝‍👨%@", leftSkin, rightSkin]];
                        break;
                    case 2:
                        [variants addObject:[NSString stringWithFormat:@"👩%@‍🤝‍👨%@", leftSkin, rightSkin]];
                        break;
                }
            }
        }
        if (ipad) {
            NSMutableArray *trueVariants = [NSMutableArray array];
            for (NSInteger index = 0; index < 30; ++index) {
                NSInteger insertIndex = ((index % 5) * 6) + (index / 5);
                [trueVariants addObject:variants[insertIndex]];
            }
            variants = trueVariants;
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
    return tree;
}

%end

%hook UIKBTree

- (void)setRepresentedString:(NSString *)string {
    %orig(overrideNewVariant ? [PSEmojiUtilities overrideKBTreeEmoji:string] : string);
}

%end