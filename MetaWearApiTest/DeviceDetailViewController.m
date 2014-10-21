/**
 * DeviceDetailViewController.m
 * MetaWearApiTest
 *
 * Created by Stephen Schiffli on 7/30/14.
 * Copyright 2014 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights
 * granted under the terms of a software license agreement between the user who
 * downloaded the software, his/her employer (which must be your employer) and
 * MbientLab Inc, (the "License").  You may not use this Software unless you
 * agree to abide by the terms of the License which can be found at
 * www.mbientlab.com/terms . The License limits your use, and you acknowledge,
 * that the  Software may not be modified, copied or distributed and can be used
 * solely and exclusively in conjunction with a MbientLab Inc, product.  Other
 * than for the foregoing purpose, you may not use, reproduce, copy, prepare
 * derivative works of, modify, distribute, perform, display or sell this
 * Software and/or its documentation for any purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
 * MBIENTLAB OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE,
 * STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED
 * TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST
 * PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
 * DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software,
 * contact MbientLab Inc, at www.mbientlab.com.
 */

#import "DeviceDetailViewController.h"
#import "MBProgressHUD.h"
#import "APLGraphView.h"

@interface DeviceDetailViewController () <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *connectionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *tempratureLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *accelerometerScale;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sampleFrequency;
@property (weak, nonatomic) IBOutlet UISwitch *highPassFilterSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *lowNoiseSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *activePowerScheme;
@property (weak, nonatomic) IBOutlet UISwitch *autoSleepSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sleepSampleFrequency;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sleepPowerScheme;

@property (weak, nonatomic) IBOutlet APLGraphView *accelerometerGraph;

@property (weak, nonatomic) IBOutlet UILabel *mechanicalSwitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLevelLabel;
@property (weak, nonatomic) IBOutlet UITextField *hapticPulseWidth;
@property (weak, nonatomic) IBOutlet UITextField *hapticDutyCycle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gpioPinSelector;
@property (weak, nonatomic) IBOutlet UILabel *gpioPinDigitalValue;
@property (weak, nonatomic) IBOutlet UILabel *gpioPinAnalogValue;

@property (weak, nonatomic) IBOutlet UIButton *startAccelerometer;
@property (weak, nonatomic) IBOutlet UIButton *stopAccelerometer;

@property (weak, nonatomic) IBOutlet UILabel *mfgNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *hwRevLabel;
@property (weak, nonatomic) IBOutlet UILabel *fwRevLabel;

@property (weak, nonatomic) IBOutlet UILabel *firmwareUpdateLabel;

@property (strong, nonatomic) UIView *grayScreen;
@property (strong, nonatomic) NSMutableArray *accelerometerDataArray;
@property (nonatomic) BOOL accelerometerRunning;
@property (nonatomic) BOOL switchRunning;
@end

@implementation DeviceDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.grayScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height - 120)];
    self.grayScreen.backgroundColor = [UIColor grayColor];
    self.grayScreen.alpha = 0.4;
    [self.view addSubview:self.grayScreen];
    
    [self.stopAccelerometer setEnabled:FALSE];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self connectDevice:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.accelerometerRunning) {
        [self stopAccelerationPressed:nil];
    }
    if (self.switchRunning) {
        [self StopSwitchNotifyPressed:nil];
    }
}

- (void)setConnected:(BOOL)on
{
    [self.connectionSwitch setOn:on animated:YES];
    [self.grayScreen setHidden:on];
}

- (void)connectDevice:(BOOL)on
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (on) {
        hud.labelText = @"Connecting...";
        [self.device connecWithHandler:^(NSError *error) {
            [self setConnected:(error == nil)];
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                hud.labelText = @"Connected!";
                [hud hide:YES afterDelay:0.5];
            }
        }];
    } else {
        hud.labelText = @"Disconnecting...";
        [self.device disconnectWithHandler:^(NSError *error) {
            [self setConnected:NO];
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                hud.labelText = @"Disconnected!";
                [hud hide:YES afterDelay:0.5];
            }
        }];
    }
}

- (IBAction)connectionSwitchPressed:(id)sender
{
    [self connectDevice:self.connectionSwitch.on];
}

- (IBAction)readTempraturePressed:(id)sender
{
    [self.device.temperature readTemperatureWithHandler:^(NSDecimalNumber *temp, NSError *error) {
        self.tempratureLabel.text = [temp stringValue];
    }];
}

- (IBAction)turnOnGreenLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor greenColor] withIntensity:0.25];
}
- (IBAction)flashGreenLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor greenColor] withIntensity:0.25];
}

- (IBAction)turnOnRedLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor redColor] withIntensity:0.25];
}
- (IBAction)flashRedLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor redColor] withIntensity:0.25];
}

- (IBAction)turnOnBlueLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor blueColor] withIntensity:0.25];
}
- (IBAction)flashBlueLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor blueColor] withIntensity:0.25];
}

- (IBAction)turnOffLEDPressed:(id)sender
{
    [self.device.led setLEDOn:NO withOptions:1];
}

- (IBAction)readSwitchPressed:(id)sender
{
    [self.device.mechanicalSwitch readSwitchStateWithHandler:^(BOOL isPressed, NSError *error) {
        self.mechanicalSwitchLabel.text = isPressed ? @"Down" : @"Up";
    }];
}

- (IBAction)startSwitchNotifyPressed:(id)sender
{
    self.switchRunning = YES;
    [self.device.mechanicalSwitch.switchUpdateEvent startNotificationsWithHandler:^(NSNumber *isPressed, NSError *error) {
        self.mechanicalSwitchLabel.text = isPressed.boolValue ? @"Down" : @"Up";
    }];
}

- (IBAction)StopSwitchNotifyPressed:(id)sender
{
    self.switchRunning = NO;
    [self.device.mechanicalSwitch.switchUpdateEvent stopNotifications];
}

- (IBAction)readBatteryPressed:(id)sender
{
    [self.device readBatteryLifeWithHandler:^(NSNumber *number, NSError *error) {
        self.batteryLevelLabel.text = [number stringValue];
    }];
}

- (IBAction)readRSSIPressed:(id)sender
{
    [self.device readRSSIWithHandler:^(NSNumber *number, NSError *error) {
        self.rssiLevelLabel.text = [number stringValue];
    }];
}

- (IBAction)readDeviceInfoPressed:(id)sender
{
    self.mfgNameLabel.text = self.device.deviceInfo.manufacturerName;
    self.serialNumLabel.text = self.device.deviceInfo.serialNumber;
    self.hwRevLabel.text = self.device.deviceInfo.hardwareRevision;
    self.fwRevLabel.text = self.device.deviceInfo.firmwareRevision;
}

- (IBAction)resetDevicePressed:(id)sender
{
    // Resetting causes a disconnection
    [self setConnected:NO];
    [self.device resetDevice];
}

- (IBAction)checkForFirmwareUpdatesPressed:(id)sender
{
    [self.device checkForFirmwareUpdateWithHandler:^(BOOL isTrue, NSError *error) {
        self.firmwareUpdateLabel.text = isTrue ? @"Avaliable!" : @"Up To Date";
    }];
}

- (IBAction)updateFirmware:(id)sender
{
    // Pause the screen while update is going on
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.labelText = @"Updating...";
    
    [self.device updateFirmwareWithHandler:^(NSError *error) {
        hud.mode = MBProgressHUDModeText;
        if (error) {
            hud.labelText = error.localizedDescription;
            NSLog(@"Firmware update error: %@", error.localizedDescription);
        } else {
            hud.labelText = @"Success!";
        }
        [hud hide:YES afterDelay:2.5];
    } progressHandler:^(float number, NSError *error) {
        hud.progress = number;
        if (number == 1.0) {
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.labelText = @"Resetting...";
        }
    }];
}

- (IBAction)startHapticDriverPressed:(id)sender
{
    uint8_t dcycle = [self.hapticDutyCycle.text intValue];
    uint16_t pwidth = [self.hapticPulseWidth.text intValue];
    [self.device.hapticBuzzer startHapticWithDutyCycle:dcycle pulseWidth:pwidth completion:nil];
}

- (IBAction)startiBeaconPressed:(id)sender
{
    [self.device.iBeacon setBeaconOn:YES];
}

- (IBAction)stopiBeaconPressed:(id)sender
{
    [self.device.iBeacon setBeaconOn:NO];
}

- (IBAction)setPullUpPressed:(id)sender
{
    [self.device.gpio configurePin:self.gpioPinSelector.selectedSegmentIndex type:MBLPinConfigurationPullup];
}
- (IBAction)setPullDownPressed:(id)sender
{
    [self.device.gpio configurePin:self.gpioPinSelector.selectedSegmentIndex type:MBLPinConfigurationPulldown];
}
- (IBAction)setNoPullPressed:(id)sender
{
    [self.device.gpio configurePin:self.gpioPinSelector.selectedSegmentIndex type:MBLPinConfigurationNopull];
}
- (IBAction)setPinPressed:(id)sender
{
    [self.device.gpio setPin:self.gpioPinSelector.selectedSegmentIndex toDigitalValue:YES];
}
- (IBAction)clearPinPressed:(id)sender
{
    [self.device.gpio setPin:self.gpioPinSelector.selectedSegmentIndex toDigitalValue:NO];
}
- (IBAction)readDigitalPressed:(id)sender
{
    [self.device.gpio readDigitalPin:self.gpioPinSelector.selectedSegmentIndex handler:^(BOOL isTrue, NSError *error) {
        self.gpioPinDigitalValue.text = isTrue ? @"1" : @"0";
    }];
}
- (IBAction)readAnalogPressed:(id)sender
{
    [self.device.gpio readAnalogPin:self.gpioPinSelector.selectedSegmentIndex mode:MBLAnalogReadModeFixed handler:^(NSDecimalNumber *number, NSError *error) {
        self.gpioPinAnalogValue.text = [number stringValue];
    }];
}

- (IBAction)startAccelerationPressed:(id)sender
{
    if (self.accelerometerScale.selectedSegmentIndex == 0) {
        self.accelerometerGraph.fullScale = 2;
    } else if (self.accelerometerScale.selectedSegmentIndex == 1) {
        self.accelerometerGraph.fullScale = 4;
    } else {
        self.accelerometerGraph.fullScale = 8;
    }
    
    self.device.accelerometer.fullScaleRange = (int)self.accelerometerScale.selectedSegmentIndex;
    self.device.accelerometer.sampleFrequency = (int)self.sampleFrequency.selectedSegmentIndex;
    self.device.accelerometer.highPassFilter = self.highPassFilterSwitch.on;
    self.device.accelerometer.lowNoise = self.highPassFilterSwitch.on;
    self.device.accelerometer.activePowerScheme = (int)self.activePowerScheme.selectedSegmentIndex;
    self.device.accelerometer.autoSleep = self.autoSleepSwitch.on;
    self.device.accelerometer.sleepSampleFrequency = (int)self.sleepSampleFrequency.selectedSegmentIndex;
    self.device.accelerometer.activePowerScheme = (int)self.activePowerScheme.selectedSegmentIndex;
   
    [self.startAccelerometer setEnabled:FALSE];
    [self.stopAccelerometer setEnabled:TRUE];
    self.accelerometerRunning = YES;
    // These variables are used for data recording
    self.accelerometerDataArray = [[NSMutableArray alloc] initWithCapacity:1000];
    
    [self.device.accelerometer.dataReadyEvent startNotificationsWithHandler:^(MBLAccelerometerData *acceleration, NSError *error) {
        [self.accelerometerGraph addX:acceleration.x y:acceleration.y z:acceleration.z];
        // Add data to data array for saving
        [self.accelerometerDataArray addObject:acceleration];
    }];
}

- (IBAction)stopAccelerationPressed:(id)sender
{
    [self.device.accelerometer.dataReadyEvent stopNotifications];
    self.accelerometerRunning = NO;

    [self.startAccelerometer setEnabled:TRUE];
    [self.stopAccelerometer setEnabled:FALSE];
}

- (IBAction)sendDataPressed:(id)sender
{
    NSMutableData *accelerometerData = [NSMutableData data];
    for (MBLAccelerometerData *dataElement in self.accelerometerDataArray) {
        @autoreleasepool {
            [accelerometerData appendData:[[NSString stringWithFormat:@"%f,%f,%f,%f\n",
                                            dataElement.intervalSinceCaptureBegan,
                                            dataElement.x,
                                            dataElement.y,
                                            dataElement.z] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    [self sendMail:accelerometerData];
}

- (void)sendMail:(NSData *)attachment
{
    if (![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:@"Mail Error" message:@"This device does not have an email account setup" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }

    // Get current Time/Date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    // Some filesystems hate colons
    NSString *dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    // I hate spaces in dates
    dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    // OS hates forward slashes
    dateString = [dateString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
    emailController.mailComposeDelegate = self;
    
    // attachment
    NSString *name = [NSString stringWithFormat:@"AccData_%@.txt", dateString, nil];
    [emailController addAttachmentData:attachment mimeType:@"text/plain" fileName:name];
    
    // subject
    NSString *subject = [NSString stringWithFormat:@"Accelerometer Data %@.txt", dateString, nil];
    [emailController setSubject:subject];
    
    NSString *messageBody = [NSString stringWithFormat:@"The data was recorded on %@.", dateString,nil];
    [emailController setMessageBody:messageBody isHTML:NO];
    
    [self presentViewController:emailController animated:YES completion:NULL];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
