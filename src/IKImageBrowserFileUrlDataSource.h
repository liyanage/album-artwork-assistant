//
//  IKImageBrowserFileUrlDataSource.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 23.07.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "Quartz/Quartz.h"


@protocol IKImageBrowserFileUrlDataSource

-(NSURL *)fileUrlForItemAtIndex:(int)index;

@end

