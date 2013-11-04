//
//  FileHelper.h
//  QQMusicForIphoneDemo
//
//  Created by jordenwu-Mac on 10-8-20.
//  Copyright 2010 tencent.com. All rights reserved.
//文件管理的帮助类
#import <Foundation/Foundation.h>
@interface FileHelper : NSObject 
{
	NSFileManager * fileManager;
}
@property(nonatomic,readonly)NSFileManager * fileManager;

+(FileHelper *)shareFileHelper;

//获得文件的全部路径：因为iPhone的缘故，它每次和iTuns更新程序，都会重新生成一个
+(NSString*)getFullFilePath:(NSString*)filePath;

//文件是否存在
+(BOOL)fileIsExistWithPath:(NSString *)filePath;
//创建单一文件
+(BOOL)createFileWithPath:(NSString *)filePath;
//删除单一文件
+(BOOL)deleteFileWithPath:(NSString *)filePath;
//创建目录
+(BOOL)createDirWithPath:(NSString *)dirPath;
//目录是否存在
+(BOOL)dirIsExistWithPath:(NSString *)dirPath;
//删除目录
+(BOOL)deleteDirWithPath:(NSString *)dirPath;
// 获得程序目录的Documents目录路径
+(NSString *)getDocumentsPath;
// 获得程序目录的Library目录路径
+(NSString *)getLibraryPath;
//获得程序临时目录路径
+(NSString *)getTmpPath;

+(unsigned long long)getFileSizeWithPath:(NSString*)filePath;

+(unsigned long long)getFileSystemFreeSize;

+(void)moveFile:(NSString*)file ToNewFile:(NSString*)newFile;
+(void)copyFile:(NSString*)file ToNewFile:(NSString*)newFile;
@end
