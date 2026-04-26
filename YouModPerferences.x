#import "Headers.h"

#define Prefix @"YouMod"

static NSBundle *YouModBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:Prefix ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:PS_ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), Prefix]];
    });
    return bundle;
}

#define LOC(x) [YouModBundle() localizedStringForKey:x value:nil table:nil]

@implementation YouModPrefsManager

+ (instancetype)sharedManager {
    static YouModPrefsManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

// Import
- (void)importYouModSettingsFromVC:(UIViewController *)vc {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.apple.property-list", @"public.item"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [vc presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *selectedFileURL = urls.firstObject;
    if (!selectedFileURL) return;
    NSDictionary *importedData = [NSDictionary dictionaryWithContentsOfURL:selectedFileURL];
    // Vaild plist check
    if (!importedData || ![importedData isKindOfClass:[NSDictionary class]]) {
        YTAlertView *alertView = [%c(YTAlertView) infoDialog];
        alertView.title = LOC(@"ERROR");
        alertView.subtitle = LOC(@"ERROR_INVALID_FILE");
        [alertView show];
        return;
    }
    BOOL foundKeys = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *key in importedData) {
        if ([key hasPrefix:Prefix]) {
            [defaults setObject:importedData[key] forKey:key];
            foundKeys = YES;
        }
    }
    // Check if there's any YouMod key
    if (!foundKeys) {
        YTAlertView *alertView = [%c(YTAlertView) infoDialog];
        alertView.title = LOC(@"ERROR");
        alertView.subtitle = LOC(@"ERROR_NO_KEYS_IMPORT");
        [alertView show];
        return;
    }
    [defaults synchronize];
    // Success Alert with Restart
    YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
        exit(0);
    } actionTitle:LOC(@"YES")];
    alertView.title = LOC(@"IMPORT_DONE");
    alertView.subtitle = LOC(@"APPLY_DESC"); // "Restart required"
    [alertView show];
}

// Export
- (void)exportYouModSettingsFromVC:(UIViewController *)vc {
    NSDictionary *allSettings = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    NSMutableDictionary *youModOnly = [NSMutableDictionary dictionary];
    for (NSString *key in allSettings) {
        if ([key hasPrefix:Prefix]) {
            youModOnly[key] = allSettings[key];
        }
    }
    if (youModOnly.count == 0) {
        YTAlertView *alertView = [%c(YTAlertView) infoDialog];
        alertView.title = LOC(@"ERROR");
        alertView.subtitle = LOC(@"ERROR_NO_KEYS_EXPORT");
        [alertView show];
        return;
    }
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"YouMod_Preferences.plist"];
    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    [youModOnly writeToURL:fileURL atomically:YES];

    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[fileURL] asCopy:YES];
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        picker.popoverPresentationController.sourceView = vc.view;
    }
    [vc presentViewController:picker animated:YES completion:nil];
}

// Reset
- (void)restoreYouModDefaults {
    YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        for (NSString *key in [defaults dictionaryRepresentation]) {
            if ([key hasPrefix:Prefix]) {
                [defaults removeObjectForKey:key];
            }
        }
        [defaults setBool:YES forKey:AutoClearCache];
        [defaults setBool:YES forKey:YTPremiumLogo];
        [defaults setBool:YES forKey:HideCreateButton];
        [defaults setBool:YES forKey:HideCastButtonNav];
        [defaults setBool:YES forKey:HideCastButtonPlayer];
        [defaults synchronize];
        exit(0);
    } actionTitle:LOC(@"YES")];
    alertView.title = LOC(@"WARNING");
    alertView.subtitle = LOC(@"RESETDEFAULT");
    [alertView show];
}

@end
