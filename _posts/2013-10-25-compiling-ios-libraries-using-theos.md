---
layout: post
title: Compiling iOS Libraries using Theos
categories: [security]
tags: [iOS]
description: Compiling iOS shared libraries with theos
---

If you want to compile a shared library for iOS, particularly for Mobile
Substrate, here are some easy enough steps to do it all via CLI.
<h2>Setup</h2>
You need Theos installed, normally into /opt/theos. Follow the getting started
guide
<ul>
  <li><a
href="http://iphonedevwiki.net/index.php/Theos/Getting_Started">http://iphonedevwiki.net/index.php/Theos/Getting_Started</a></li>
</ul>
Then create a new Theo project. The following is named SampleCrack
<pre class="brush:shell">user@myhost&gt; $THEOS/bin/nic.pl
NIC 2.0 - New Instance Creator
------------------------------
[1.] iphone/application
[2.] iphone/library
[3.] iphone/preference_bundle
[4.] iphone/tool
[5.] iphone/tweak
Choose a Template (required): 2
Project Name (required): SampleCrack
Package Name [com.yourcompany.samplecrack]:
Author/Maintainer Name [c0ffee]: 
Instantiating iphone/library in samplecrack/...
Done.</pre>
Then look about
<pre class="brush:shell">user@myhost&gt; cd samplecrack
user@myhost&gt; ls
./working/samplecrack
Makefile       SampleCrack.mm control        theos</pre>
We are going to be using captain hook. Check it out
<pre class="brush:shell">user@myhost&gt; git clone
git://github.com/rpetrich/CaptainHook.git</pre>
<h2>Write</h2>
Then let's write the code, make sure you mod it to your liking, sadly there are
no docs for CaptainHook.
<pre class="brush:shell">user@myhost&gt; cat &gt; SampleCrack.h</pre>
<pre class="brush:c">#import &lt;Foundation/Foundation.h&gt;

@interface SampleCrack : NSObject
@end</pre>
<pre class="brush:shell">user@myhost&gt; cat &gt; SampleCrack.mm</pre>
<pre class="brush:c">#import "SampleCrack.h"
#import "Foundation/Foundation.h"
#import "CaptainHook/CaptainHook.h"
#include "notify.h"

@implementation SampleCrack
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
}</pre>
<h2>Build</h2>
Then we compile:
<pre class="brush:shell">user@myhost&gt; make</pre>
If you get an error that looks anything like the following:
<pre
class="brush:shell">./working/samplecrack/theos/include/IOSurface/IOSurface.h:20:10:
fatal error: 'IOSurface/IOSurfaceAPI.h' file not found
#include &lt;IOSurface/IOSurfaceAPI.h&gt;</pre>
Then try including the IOSurfaceAPI.h in, I had to do this on lion.
<pre class="brush:shell">&gt; cp
/System/Library/Frameworks/IOSurface.framework/Headers/IOSurfaceAPI.h
./theos/include/IOSurface/</pre>
You will probably need to comment out the following lines also:
<pre class="brush:c">    /* This call lets you get an xpcobject_t that holds
a reference to the IOSurface.
    Note: Any live XPC objects created from an IOSurfaceRef implicity increase
the IOSurface's global use
    count by one until the object is destroyed. */
    // xpc_object_t IOSurfaceCreateXPCObject(IOSurfaceRef aSurface)
    // IOSFC_AVAILABLE_STARTING(_MAC_10_7, __IPHONE_NA);

    /* This call lets you take an xpcobject_t created via IOSurfaceCreatePort()
and recreate an IOSurfaceRef from it. */
    // IOSurfaceRef IOSurfaceLookupFromXPCObject(xpc_object_t xobj)
    // IOSFC_AVAILABLE_STARTING(_MAC_10_7, __IPHONE_NA);</pre>
See <a
href="http://stackoverflow.com/questions/10891846/error-compiling-tweak-in-theos">this
stack overflow post</a> if you want more detail.

You are also going to need a copy of ldid. If you have ports, try there. Brew
doesn't seem to hold a copy (They gave up on it because it fails with clang?
Use llvm g++). If those fail check try making it yourself:
<pre class="brush:shell">git clone git://git.saurik.com/ldid.git
cd ldid
git submodule update --init
./make.sh
cp -f ./ldid $THEOS/bin/ldid</pre>
Make sure you drop it into $THEOS/bin/ldid
<pre class="brush:shell">scp ./obj/SampleCrack.dylib
root@iphone:/Library/MobileSubstrate/
ssh root@iphone
root@iphone's password: 
iphone:~ root# 
ldid -S SampleCrack.ldid</pre>
Now you've got the dependencies, make it
<pre class="brush:shell">user@myhost&gt; export SDKVERSION=7.0
user@myhost&gt; make</pre>
And you've got yourself a nice library
<pre class="brush:shell">&gt; file obj/SampleCrack.dylib
~/Documents/Customer/Documents/Elavon/working/samplecrack
obj/SampleCrack.dylib: Mach-O universal binary with 2 architectures: [arm_v7:
Mach-O arm_v7 dynamically linked shared library] [arm subarchitecture=11:
Mach-O arm subarchitecture=11 dynamically linked shared library]</pre>
&nbsp;
