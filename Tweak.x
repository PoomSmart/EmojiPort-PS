#define CHECK_TARGET
#import <dlfcn.h>
#import <PSHeader/PS.h>

%ctor {
    if (isTarget(TargetTypeApps)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiPort/EmojiAttributes.dylib", RTLD_LAZY);
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiPort/EmojiLocalization.dylib", RTLD_LAZY);
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiPort/EmojiResources.dylib", RTLD_LAZY);
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiPort/EmojiPortPSReal.dylib", RTLD_LAZY);
    }
}