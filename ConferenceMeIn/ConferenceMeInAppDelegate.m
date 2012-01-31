//
//  ConferenceMeInAppDelegate.m
//  ConferenceMeIn
//
//  Created by philip penn on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConferenceMeInAppDelegate.h"

#import "ConferenceMeInMasterViewController.h"
#import "CMIMasterViewController.h"

NSString *kCalendarTypeKey	= @"calendarTypeKey";
NSString *kfetch28DaysEventsKey = @"fetch28DaysEventsKey";

@implementation ConferenceMeInAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize calendarType = _calendarType;
@synthesize debugMode = _debugMode;

ConferenceMeInMasterViewController* _conferenceMeInMasterViewController;
CMIMasterViewController* _cmiMasterViewController;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];

}

- (void)setupByPreferences
{
    NSLog(@"NSUserDefaults dump: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRun"] ) {
    //do initialization stuff here...
        
		// no default values have been set, create them here based on what's in our Settings bundle info
		//
		NSString *pathStr = [[NSBundle mainBundle] bundlePath];
		NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
		NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
        
		NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
		NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
        
		NSNumber *calendarTypeDefault = nil;
		bool fetch28DaysEventsDefault = [[NSUserDefaults standardUserDefaults] boolForKey:kfetch28DaysEventsKey];
        
		NSDictionary *prefItem;
		for (prefItem in prefSpecifierArray)
		{
			NSString *keyValueStr = [prefItem objectForKey:@"Key"];
			id defaultValue = [prefItem objectForKey:@"DefaultValue"];
			
			if ([keyValueStr isEqualToString:kCalendarTypeKey])
			{
				calendarTypeDefault = defaultValue;
			}
//			else if ([keyValueStr isEqualToString:kfetch28DaysEventsKey])
//			{
//				fetch28DaysEventsDefault = [prefItem objectForKey:@"DefaultValue"];
//			}
		}
        
        NSDate *today = [NSDate date];        

		// since no default values have been set (i.e. no preferences file created), create it here		
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                     calendarTypeDefault, kCalendarTypeKey,
                                     today, @"firstRun",
                                     nil];
        
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"firstRun"];
		[[NSUserDefaults standardUserDefaults] setBool:fetch28DaysEventsDefault forKey:kfetch28DaysEventsKey];
        
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
    
	// we're ready to go, so lastly set the key preference values
	self.calendarType = [[NSUserDefaults standardUserDefaults] integerForKey:kCalendarTypeKey];
    self.debugMode = [[NSUserDefaults standardUserDefaults] boolForKey:kfetch28DaysEventsKey];
}

// we are being notified that our preferences have changed (user changed them in the Settings app)
// so read in the changes and update our UI.
//
- (void)defaultsChanged:(NSNotification *)notif
{
    @try {
    
        [self setupByPreferences];
    
        [_cmiMasterViewController reloadTableScrollToNow];
        
        UITableView *tableView = ((UITableViewController *)self.navigationController.visibleViewController).    tableView;
        [tableView reloadData];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e); 
    }
    @finally {
        // Added to show finally works as well
    }    
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	[self setupByPreferences];
    
    // listen for changes to our preferences when the Settings app does so,
    // when we are resumed from the backround, this will give us a chance to update our UI
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    ConferenceMeInMasterViewController *masterViewController = [[ConferenceMeInMasterViewController alloc] initWithNibName:@"ConferenceMeInMasterViewController" bundle:nil];
    CMIMasterViewController *masterViewController2 = [[CMIMasterViewController alloc] init];// bundle:nil];
    _conferenceMeInMasterViewController = masterViewController;
    _cmiMasterViewController = masterViewController2;
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController2];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


@end
