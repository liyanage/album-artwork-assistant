//
//  StatusDelegateProtocol.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 19.07.08.
//  Copyright 2008-2009 Liyanage <http://www.entropy.ch>. All rights reserved.
//

@protocol StatusDelegateProtocol

- (void)startBusy:(NSString *)message;
- (void)clearBusy;
- (BOOL)displayErrorWithTitle:(NSString *)title message:(NSString *)message;

@end
