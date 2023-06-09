////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 WabiRealm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "Tick.h"

@interface TodayViewController () <NCWidgetProviding>

@property(nonatomic, strong) UIButton *button;
@property(nonatomic, strong) Tick *tick;
@property(nonatomic, strong) RLMNotificationToken *notificationToken;

@end

@implementation TodayViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.preferredContentSize = CGSizeMake(0, 200.0);
  RLMRealmConfiguration *configuration =
      [RLMRealmConfiguration defaultConfiguration];
  configuration.fileURL = [[[NSFileManager defaultManager]
      containerURLForSecurityApplicationGroupIdentifier:
          @"group.io.realm.examples.extension"]
      URLByAppendingPathComponent:@"extension.realm"];
  [RLMRealmConfiguration setDefaultConfiguration:configuration];
  self.tick = [Tick allObjects].firstObject;
  if (!self.tick) {
    [[RLMRealm defaultRealm] transactionWithBlock:^{
      self.tick = [Tick createInDefaultRealmWithValue:@[ @"", @0 ]];
    }];
  }
  self.notificationToken = [self.tick.realm
      addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        // Occasionally, respond immediately to the notification by triggering a
        // new notification.
        if (self.tick.count % 19 == 0) {
          [self tock];
        }
        [self updateLabel];
      }];
  self.button = [UIButton buttonWithType:UIButtonTypeSystem];
  self.button.frame = self.view.bounds;
  [self.button addTarget:self
                  action:@selector(tock)
        forControlEvents:UIControlEventTouchUpInside];
  self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.button setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];
  [self.view addSubview:self.button];
  [self updateLabel];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.button.frame = self.view.bounds;
  [self updateLabel];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self tock];
  [self updateLabel];
}

- (void)updateLabel {
  [self.button setTitle:@(self.tick.count).stringValue
               forState:UIControlStateNormal];
}

- (void)tock {
  [[RLMRealm defaultRealm] transactionWithBlock:^{
    self.tick.count++;
  }];
}

@end
