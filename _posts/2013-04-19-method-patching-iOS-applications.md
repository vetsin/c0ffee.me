---
layout: post
title: Method patching on iOS applications
categories: [security]
tags: []
description: Method patching a function (e.g. a JailBreak check) on a rooted iOS device
---

# Summary 

These are the steps needed to crack (method patch the jailbreak function) an
iOS application to work on a rooted iOS device. This example uses "Sample.app"
from within OSX Lion. Mileage may vary.

# Requirements

iOS Physical device rooted with cydia and some basic tools:

* syslogd - See all console output in /var/log/
* openssh
* adv-cmds - Tools like ps, kill, etc
* GNU debugger - (If GDB is working unexpectedly, install from
radare.org)
* Darwin CC Tools - otool and such

Get the application and install it. This guide is assuming an encrypted IPA
(compiled for ARM) distribution.

## Decrypting

In the cases in which the binary is encrypted, you must decrypt. The easiest
way to do this is to find a program to do it for you (Google this if you want
to skip this step). The surefire (manual) way  to do this is to execute the
binary breaking at the end of the decoding stub. This will leave the entire
un-ecrypted binary in memory where you can then dump it to disk.

Locate application binary within the application folder on the device. e.g.:

{% highlight sh %}
/private/var/mobile/Applications/BC2DA09D-7189-44E8-B190-2EE03BAAAAA8/SampleApp.app/SampleApp
{% endhighlight %}

Then check application for encryption:

{% highlight shell %}
root# otool -l SampleApp | grep -B5 cryptid
Load command 11
 cmd LC_ENCRYPTION_INFO
 cmdsize 20
 cryptoff 4096
 cryptsize 94208
 cryptid 1
--
{% endhighlight %}

Given `cryptid 1` (`0` == Not Encrypted). Keep note of the cryptsize, we will use
this value later.

Verify application is not FAT (That is does not contain multiple versions):

{% highlight sh %}
root# otool -f SampleApp
{% endhighlight %}

If the application contains multiple versions, you must use lipo to extract the
correct (armv7) version and continue.

Given a single encrypted binary:

{% highlight sh %}
root# gdb --quiet -e ./SampleApp
...
(gdb) set sharedlibrary load-rules ".*" ".*" none
(gdb) set inferior-auto-start-dyld off
(gdb) set sharedlibrary preload-libraries off
(gdb) rb doModInitFunctions
Breakpoint 1 at 0x2fe0cece
&lt;function, no debug info&gt;
__dyld__ZN16ImageLoaderMachO18doModInitFunctionsERKN11ImageLoader11LinkContextE;
(gdb) r
Starting program:
/private/var/mobile/Applications/BC2DA09D-7189-44E8-B190-2EE03BAAAAA8/SampleApp.app/SampleApp.app/SampleApp
Breakpoint 1, 0x2fe0cece in
__dyld__ZN16ImageLoaderMachO18doModInitFunctionsERKN11ImageLoader11LinkContextE
()
{% endhighlight %}

Dump the binary from memory to disk:
<pre class="brush:shell">dump binary memory /var/root/dump 0x2000 0x18000</pre>
See `python -c 'print(hex(4096+94208))'` from crytpid analysis for the end limit,
which is 0x18000 bytes in the example. You will have to substitute your own
value in.

Then pull the binary off phone and use classdump
<pre class="brush:shell">scp root@iphone:/var/root/dump ./SampleApp
./class-dump SampleApp &gt; SampleAppDump</pre>
Examine dump for a root checking function (probably returns BOOL or _Bool) with
some grep-fu. You will most likely find multiple functions. If the application
is more complicated, cycript may help you find it.

## Setup

You can either follow my other instructions on <a
href="http://c0ffee.me/compiling-ios-libraries-using-theos/">compiling iOS
libraries using Theos</a> (Reccomended!), or do the following:
<ul>
  <li>Create a Cocoa Touch Static Library XCode Project.</li>
  <li>Setup dylib compiling for iOS from XCode from the instructions at <a
href="http://blog.iosplace.com/?p=33">"Build and use dylib on iOS" by iOS
Place</a>. I believe there are other ways to compile outside of XCode, if you
have any success there drop a comment.</li>
  <li>Create private signing certificates if you don't have  a development
license by following <a
href="http://www.securitylearn.net/2012/12/26/build-ipa-file-using-xcode-without-provisioning-profile/">"Build
ipa file using XCode without provisioning profile" by SecurityLearn</a>.</li>
</ul>
Install MobileSubstrate on the iOS device. You can check if it's installed by
looking for /Library/MobileSubstrate.
<h2>Writing</h2>
Checkout <a href="https://github.com/rpetrich/CaptainHook">CaptainHook</a> into
the project into the project. Mine is called NoCheck saved in
~/Documents/workspace
<pre class="brush:shell">user@box&gt; cd ~/Documents/workspace/NoCheck/NoCheck
user@box&gt; git clone git://github.com/rpetrich/CaptainHook.git</pre>
Write the code itself using the lib. This sample code was referenced from the
<a
href="http://blog.mdsec.co.uk/2012/05/ios-application-insecurity-whitepaper.html">MDSec
iOS doc</a>. Read it if you haven't.

{% highlight c %}
#import "NoCheck.h"
#import "Foundation/Foundation.h"
#import "CaptainHook/CaptainHook.h"
#include "notify.h"

@implementation NoCheck
-(id)init
{
    if ((self = [super init])){} return self;
}
@end

@class SampleAppViewController;
CHDeclareClass(SampleAppViewController);
CHOptimizedMethod(0, self, _Bool, SampleAppViewController, isDeviceRooted)
{
    NSLog(@"####### isJailBroken hooked"); // Logging saves lives
    return true;
}

CHConstructor {
    @autoreleasepool {
        CHLoadLateClass(SampleAppViewController);
        CHHook(0, SampleAppViewController, isDeviceRooted); // register hook
    }
}
{% endhighlight %}
&nbsp;

All is needed now compile to dylib by running the application and copying it
over. Press the run button to compile. Find it by looking at the left hand bar,
mine was located at
/Users/user/Library/Developer/Xcode/DerivedData/NoCheck-abheoijxmwkxefbirkgyhsismoxg/Build/Products/Debug-iphoneos

Copy the output file to /Library/MobileSubstrate/DynamicLibraries/
<pre class="brush:shell">user@box&gt; cd
/Users/user/Library/Developer/Xcode/DerivedData/NoCheck-abheoijxmwkxefbirkgyhsismoxg/Build/Products/Debug-iphoneos
user@box&gt; scp ./NoCheck.dylib
root@iphone:/Library/MobileSubstrate/DynamicLibraries/</pre>
Run application and be happy. If you're not sure it worked tail your syslog
output to see if the module is loading (it will do so often) and the NSLog is
output.
