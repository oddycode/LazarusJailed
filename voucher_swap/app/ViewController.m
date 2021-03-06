//
//  ViewController.m
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import "ViewController.h"
#import "kernel_slide.h"
#import "voucher_swap.h"
#import "kernel_memory.h"
#import <mach/mach.h>
#include "post.h"
#include <sys/utsname.h>

#define DEBUG_MODE true

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *bigButton;

@end

@implementation ViewController

- (bool)voucher_swap:(id)sender {
#define CHECK(a, b) if (a < b) { printf("non-16k devices are unsupported.\n"); [sender setTitle:@"Error: 4K Device" forState:UIControlStateNormal]; return false; }
    if ([[UIDevice currentDevice].model isEqualToString:@"iPod touch"]) {
        [sender setTitle:@"Error: Device Unsupported" forState:UIControlStateNormal];
        return false;
    }
    struct utsname u;
    uname(&u);
    char read[257];
    int ii = 0;
    for (int i = 0; i < 256; i++) {
        char chr = u.machine[i];
        long num = chr - '0';
        if (num == -4 || chr == 0) {
            break;
        }
        if (num >= 0 && num <= 9) {
            read[ii] = chr;
            ii++;
        }
    }
    read[ii + 1] = 0;
    int digits = atoi(read);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CHECK(digits, 8);
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CHECK(digits, 6);
    }
    voucher_swap();
    if (!MACH_PORT_VALID(kernel_task_port)) {
        printf("tfp0 is invalid?\n");
        [sender setTitle:@"Error: TFP0 Invalid" forState:UIControlStateNormal];
        return false;
    }
    return true;
#undef CHECK
}

- (void)failure:(id)sender {
//    [sender setTitle:@"Error: Exploit"];
    self.bigButton.userInteractionEnabled = false;
}

- (IBAction)go:(id)sender {
    static int progress = 0;
    /*
     If you're running this in a method like viewDidLoad you only need the following:
     --------------------------------------------------------------------------------
     Post *post = [[Post alloc] init];
     bool success = [self voucher_swap];
     if (success) {
     sleep(1);
     [post go];
     } else {
     assert(false);
     }
     */
    if (progress == 2) {
        [sender setTitle:@"Respringing" forState:UIControlStateNormal];
    } else if (progress == 1) {
        [sender setTitle:@"Error: Unknown" forState:UIControlStateNormal];
    } else if (progress == 0) {
        [sender setTitle:@"Patching" forState:UIControlStateNormal];
    } else {
        [sender setTitle:@"Error: Unknown" forState:UIControlStateNormal];
    }
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        Post *post = [[Post alloc] init];
        if (progress == 2) {
            [post respring];
            return;
        }
        if (progress == 1) {
            return;
        }
        progress++;
        bool success = [self voucher_swap:sender];
        if (success) {
            sleep(1);
            [post go:sender];
            [sender setTitle:@"Patched (Respring Now)" forState:UIControlStateNormal];
            progress++;
        } else {
            [self failure:sender];
        }
    });
    
//    double delayInSeconds = 2.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        
//    });
}

- (bool)isBlocked {
    int blocked = 0;
    NSArray <NSString *> *array = @[@"/var/Keychains/ocspcache.sqlite3",
                                    @"/var/Keychains/ocspcache.sqlite3-shm",
                                    @"/var/Keychains/ocspcache.sqlite3-wal"];
    for (NSString *path in array) {
        if (is_symlink(path.UTF8String)) {
            blocked++;
        } else {
            return false;
        }
    }
    
    if (blocked == 3) {
        return true;
    }
    
    return false;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.bigButton setTitle:@"Checking if blocked" forState:UIControlStateNormal];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self isBlocked]) {
            [self.bigButton setTitle:@"Revokes Blocked" forState:UIControlStateNormal];
            if (DEBUG_MODE) {
                self.bigButton.userInteractionEnabled = true;
            } else {
                self.bigButton.userInteractionEnabled = false;
            }
            NSLog(@"[+] Revokes Blocked");
        } else {
            [self.bigButton setTitle:@"Block Revokes" forState:UIControlStateNormal];
            NSLog(@"[-] Not Blocked");
        }
    });
}

@end
