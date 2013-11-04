//
//  BTViewController.h
//  bluetoothShare
//
//  Created by wu on 12-9-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/Gamekit.h>
#import "AGAlertViewWithProgressbar.h"
#import "FileHelper.h"
#import "JBInfoBarManager.h"
#import <MediaPlayer/MediaPlayer.h>


extern NSString* const ACFileTransferFileSentNotification;
extern NSString* const ACFileTransferFileBeganNotification;
extern NSString* const ACFileTransferFileReceivedNotification;
extern NSString* const ACFileTransferFileFailedNotification;
extern NSString* const ACFileTransferPacketSentNotification;
extern NSString* const ACFileTransferPacketReceivedNotification;
extern NSString* const ACFileTransferPacketFailedNotification;
extern NSString* const ACFileTransferAvailabilityChangedNotification;
extern NSString* const ACFileTransferUpdatedPeersNotification;

@interface BTViewController : UIViewController<UIAlertViewDelegate,GKPeerPickerControllerDelegate,GKSessionDelegate>
{
    //amyxfliu
    GKSession * currentSession;
    UIAlertView * alertView;
    AGAlertViewWithProgressbar * transferAlert;
    AGAlertViewWithProgressbar * receiveAlert;
    NSInteger	peerStatus;
    NSInteger   shareStatus; 
    NSString * sharePeerId;
    double sendSize;
    int fileSize;
    NSNumber* packetIndex;
    NSMutableData * contents;
    NSArray* packets;
    NSString *fileName;
    NSMutableDictionary* assemblyLine;
    NSInteger totalBytes;
    NSString*key;
    NSFileHandle * videoWriteHandle;
    MPMoviePlayerViewController * moviePlayer;
}
@property (nonatomic,retain)UIAlertView * alertView;
@property (nonatomic,retain)GKSession * currentSession;
@property (nonatomic,assign)NSInteger peerStatus;
@property (nonatomic,assign)NSInteger shareStatus;
@property (nonatomic,retain) AGAlertViewWithProgressbar * transferAlert;
@property (nonatomic,retain) AGAlertViewWithProgressbar * receiveAlert;
@property (nonatomic,retain) NSString * sharePeerId;
@property (nonatomic,retain) NSMutableData * contents;
@property (nonatomic,retain) NSArray *packets;
@property (nonatomic,retain)NSString *fileName;
@property (nonatomic,retain)NSNumber *packetIndex;
@property (nonatomic,retain)NSFileHandle *videoWriteHandle;
@property (nonatomic,retain)MPMoviePlayerViewController * moviePlayer;

-(void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withPacketArr:(NSArray*)packetsArr;
@end

@interface NSData (MD5)
-(NSString*)md5;
@end