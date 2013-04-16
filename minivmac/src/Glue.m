#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <sys/time.h>
#import "AppDelegate.h"
#import "DATE2SEC.h"
#import "mnvm/MYOSGLUE.c"
#import "objc/message.h"
#import "VirtualDiskDriveController.h"

blnr SpeedStopped = falseblnr;
NSInteger numInsertedDisks;
short *SurfaceScrnBuf;
BOOL useColorMode;
short *pixelConversionTable;
id _gScreenView;
SEL _updateColorMode;
ui5b MacDateDiff;
#define UsecPerSec    1000000
#define MyInvTimeStep 16626 /* UsecPerSec / 60.14742 */
LOCALVAR ui5b TrueEmulatedTime = 0;
ui5b CurEmulatedTime = 0;
LOCALVAR ui5b OnTrueTime = 0;
LOCALVAR ui5b LastTimeSec, NextTimeSec;
LOCALVAR ui5b LastTimeUsec, NextTimeUsec;
#ifdef IncludePbufs
LOCALVAR void *PbufDat[NumPbufs];
#endif

IMPORTFUNC blnr ScreenFindChanges(ui3p screencurrentbuff,
                                  si3b TimeAdjust, si4b *top, si4b *left, si4b *bottom, si4b *right);

IMPORTFUNC ui3p GetCurDrawBuff(void);

#if 0
#pragma mark -
#pragma mark Warnings
#endif

GLOBALPROC WarnMsgUnsupportedROM(void) {
    [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnUnsupportedROM", nil)];
}

#if DetailedAbormalReport
GLOBALPROC WarnMsgAbnormal(char *s) {
    [[Helpers sharedInstance] warnMessage:[NSString stringWithFormat:NSLocalizedString(@"WarnAbnormalSituationDetailed", nil), s]];
}

#else
GLOBALPROC WarnMsgAbnormal(void) {
    [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnAbnormalSituation", nil)];
}

#endif

GLOBALPROC WarnMsgCorruptedROM(void) {
    [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnCorruptedROM", nil)];
}

#if 0
#pragma mark -
#pragma mark Screen
#endif

GLOBALPROC MyMoveBytes(anyp srcPtr, anyp destPtr, si5b byteCount) {
    (void)memcpy((char *)destPtr, (char *)srcPtr, byteCount);
}

LOCALPROC PStrFromChar(ps3p r, char x) {
    r[0] = 1;
    r[1] = (char)x;
}

void updateScreen(ui4r top, ui4r left, ui4r bottom, ui4r right) {
    // Update the surface data straight from UpdateLuminaceCopy (cut down on memcpys)
    UpdateLuminanceCopy((anyp *)SurfaceScrnBuf, top, left, bottom, right);

    objc_msgSend(_gScreenView, _updateColorMode, UseColorMode);

    // look at sending a rect - there is likely to be screen corruption under certain scenarios.
    objc_msgSend(_gScreenView, @selector(setNeedsDisplay));
}

GLOBALPROC MyDrawChangesAndClear(void) {
    if (ScreenChangedBottom > ScreenChangedTop) {
        updateScreen(ScreenChangedTop, ScreenChangedLeft,
                     ScreenChangedBottom, ScreenChangedRight);
        ScreenClearChanges();
    }
}

#if 0
#pragma mark -
#pragma mark Sound
#endif

#if MySoundEnabled
#define SOUND_SAMPLERATE 22255
#define kLn2SoundBuffers 4 /* kSoundBuffers must be a power of two, must have at least 2^2 buffers */
#define kSoundBuffers    (1 << kLn2SoundBuffers)
#define kSoundBuffMask   (kSoundBuffers - 1)
#define kLn2BuffLen      9
#define kLnBuffSz        (kLn2SoundBuffers + kLn2BuffLen)
#define My_Sound_Len     (1UL << kLn2BuffLen)
#define kBufferSize      (1UL << kLnBuffSz)
#define kBufferMask      (kBufferSize - 1)
//#define dbhBufferSize (kBufferSize + SOUND_LEN)
//#define DesiredMinFilledSoundBuffs 4

static int curFillBuffer = 0;
static int numFullBuffers = 0;

//#define FillWithSilence(p,n,v) for (int fws_i = n; --fws_i >= 0;) *p++ = v
LOCALPROC FillWithSilence(ui3p p, int n, ui3b v) {
    int i;

    for (i = n; --i >= 0; ) {
        *p++ = v;
    }
}

struct {
    bool mIsInitialized;
    bool mIsRunning;
    AudioQueueRef mQueue;
    AudioStreamBasicDescription mDataFormat;
    AudioQueueBufferRef mBuffers[kSoundBuffers];
} aq;

LOCALPROC MySound_SecondNotify(void) {
    if (!aq.mIsRunning) return;

    if (MinFilledSoundBuffs > DesiredMinFilledSoundBuffs) {
        ++CurEmulatedTime;
    }
    else if (MinFilledSoundBuffs < DesiredMinFilledSoundBuffs) {
        --CurEmulatedTime;
    }

    MinFilledSoundBuffs = kSoundBuffers;
}

LOCALPROC MySound_Start0(void) {
    ThePlayOffset = 0;
    TheFillOffset = 0;
    TheWriteOffset = 0;
    MinFilledSoundBuffs = kSoundBuffers;
#if dbglog_SoundBuffStats
    MaxFilledSoundBuffs = 0;
#endif
    wantplaying = falseblnr;

#if MySoundRecenterSilence
    LastModSample = kCenterSound;
    SilentBlockCounter = SilentBlockThreshold;
#endif
}

void MySound_Callback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    ui3p NextPlayPtr;
    ui4b PlayNowSize = 0;
    ui4b MaskedFillOffset = ThePlayOffset & kOneBuffMask;

    if (MaskedFillOffset != 0) {
        /* take care of left overs */
        PlayNowSize = kOneBuffLen - MaskedFillOffset;
        NextPlayPtr =
            TheSoundBuffer + (ThePlayOffset & kAllBuffMask);
    }
    else if (0 !=
               ((TheFillOffset - ThePlayOffset) >> kLnOneBuffLen)) {
        PlayNowSize = kOneBuffLen;
        NextPlayPtr =
            TheSoundBuffer + (ThePlayOffset & kAllBuffMask);
    }
    else {
        if (numFullBuffers) {
            /* low on sound to play. play a bit of silence */
            ThePlayOffset -= kOneBuffLen;
            NextPlayPtr =
                TheSoundBuffer + (ThePlayOffset & kAllBuffMask);
            PlayNowSize = kOneBuffLen;
            FillWithSilence(NextPlayPtr, kOneBuffLen,
                            /* 0x80 */
                            *((ui3p)NextPlayPtr + kOneBuffLen - 1));
            /* fprintf(stderr, "need silence\n"); */
        }
    }

    if (0 != PlayNowSize) {
        mBuffer->mAudioDataByteSize = PlayNowSize;
        char *mAudioData = mBuffer->mAudioData;
        //if (numFullBuffers == 0) {
        //    FillWithSilence(mAudioData, SOUND_LEN, 0x80);
        //} else {
        memcpy(mAudioData, NextPlayPtr, SOUND_LEN);
//    numFullBuffers--;
//    curReadBuffer = (curReadBuffer+1) & kSoundBuffMask;
        //}
        AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
    }
}

bool MySound_Init(void) {
    OSStatus err;

    bzero(&aq, sizeof aq);

    // create queue
    aq.mDataFormat.mSampleRate = SOUND_SAMPLERATE;
    aq.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    aq.mDataFormat.mFormatFlags = kAudioFormatFlagIsPacked;
    aq.mDataFormat.mBytesPerPacket = 1;
    aq.mDataFormat.mFramesPerPacket = 1;
    aq.mDataFormat.mBytesPerFrame = 1;
    aq.mDataFormat.mChannelsPerFrame = 1;
    aq.mDataFormat.mBitsPerChannel = 8;
    aq.mDataFormat.mReserved = 0;
    err = AudioQueueNewOutput(&aq.mDataFormat, MySound_Callback, NULL, CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &aq.mQueue);

    if (err != noErr) NSLog(@"Error %ld creating audio queue", err);

    // create buffers
    for (int i = 0; i < kSoundBuffers; i++) {
        AudioQueueAllocateBuffer(aq.mQueue, SOUND_LEN, &aq.mBuffers[i]);
        MySound_Callback(NULL, aq.mQueue, aq.mBuffers[i]);
    }

    aq.mIsInitialized = true;
    return trueblnr;
}

GLOBALPROC MySound_Start(void) {
    if (!aq.mIsInitialized || aq.mIsRunning) return;

    MySound_Start0();
    AudioQueueStart(aq.mQueue, NULL);
    aq.mIsRunning = true;
}

GLOBALPROC MySound_Stop(void) {
    wantplaying = falseblnr;

    if (!aq.mIsRunning || !aq.mIsInitialized) return;

    AudioQueueStop(aq.mQueue, false);
    aq.mIsRunning = false;
}

GLOBALPROC MySound_BeginPlaying(void) {
    MySound_Start();
}

GLOBALFUNC tpSoundSamp MySound_BeginWrite(ui4r n, ui4r *actL) {
    ui4b ToFillLen = kAllBuffLen - (TheWriteOffset - ThePlayOffset);
    ui4b WriteBuffContig =
        kOneBuffLen - (TheWriteOffset & kOneBuffMask);

    if (WriteBuffContig < n) {
        n = WriteBuffContig;
    }

    if (ToFillLen < n) {
        /* overwrite previous buffer */
        TheWriteOffset -= kOneBuffLen;
    }

    *actL = n;

    curFillBuffer = (curFillBuffer + 1) & kSoundBuffMask;
    numFullBuffers++;

    return TheSoundBuffer + (TheWriteOffset & kAllBuffMask);
}

GLOBALPROC MySound_EndWrite(ui4r actL) {
    TheWriteOffset += actL;

    if (0 == (TheWriteOffset & kOneBuffMask)) {
        /* just finished a block */

        MySound_WroteABlock();
    }

    numFullBuffers = 0;
}

//GLOBALFUNC ui3p GetCurSoundOutBuff(void) {
//    if (!aq.mIsRunning) return nullpr;
//    if (numFullBuffers == kSoundBuffers) return nullpr;
//    curFillBuffer = (curFillBuffer+1) & kSoundBuffMask;
//    numFullBuffers ++;
//    return TheSoundBuffer[curFillBuffer];
//}
#else /* if MySoundEnabled */

GLOBALFUNC ui3p GetCurSoundOutBuff(void) {
    return nullpr;
}

#endif /* if MySoundEnabled */

#if 0
#pragma mark -
#pragma mark Emulation
#endif

LOCALPROC IncrNextTime(void) {
    /* increment NextTime by one tick */
    NextTimeUsec += MyInvTimeStep;

    if (NextTimeUsec >= UsecPerSec) {
        NextTimeUsec -= UsecPerSec;
        NextTimeSec += 1;
    }
}

LOCALPROC InitNextTime(void) {
    NextTimeSec = LastTimeSec;
    NextTimeUsec = LastTimeUsec;
    IncrNextTime();
}

LOCALPROC GetCurrentTicks(void) {
    struct timeval t;

    gettimeofday(&t, NULL);
    LastTimeSec = (ui5b)t.tv_sec;
    LastTimeUsec = (ui5b)t.tv_usec;
}

void StartUpTimeAdjust(void) {
    GetCurrentTicks();
    InitNextTime();
}

LOCALFUNC si5b GetTimeDiff(void) {
    return ((si5b)(LastTimeSec - NextTimeSec)) * UsecPerSec
           + ((si5b)(LastTimeUsec - NextTimeUsec));
}

LOCALFUNC blnr CheckDateTime(void) {
    ui5b NewMacDate = time(NULL) + MacDateDiff;

    if (NewMacDate != CurMacDateInSeconds) {
        CurMacDateInSeconds = NewMacDate;
        return trueblnr;
    }

    return falseblnr;
}

LOCALPROC UpdateTrueEmulatedTime(void) {
    si5b TimeDiff;

    GetCurrentTicks();

    TimeDiff = GetTimeDiff();

    if (TimeDiff >= 0) {
        if (TimeDiff > 4 * MyInvTimeStep) {
            /* emulation interrupted, forget it */
            ++TrueEmulatedTime;
            InitNextTime();
        }
        else {
            do {
                ++TrueEmulatedTime;
                IncrNextTime();
                TimeDiff -= UsecPerSec;
            } while (TimeDiff >= 0);
        }
    }
    else if (TimeDiff < -2 * MyInvTimeStep) {
        /* clock goofed if ever get here, reset */
        InitNextTime();
    }
}

GLOBALFUNC blnr ExtraTimeNotOver(void) {
    UpdateTrueEmulatedTime();
    return TrueEmulatedTime == OnTrueTime;
}

LOCALPROC RunEmulatedTicksToTrueTime(void) {
    si3b n = OnTrueTime - CurEmulatedTime;

    if (n > 0) {
        if (CheckDateTime()) {
#if MySoundEnabled
            MySound_SecondNotify();
#endif
        }

        //if (gWeAreActive) {
        //	CheckMouseState();
        //}

        DoEmulateOneTick();
        ++CurEmulatedTime;

#if EnableMouseMotion && MayFullScreen

        if (HaveMouseMotion) {
            //AutoScrollScreen();
        }

#endif

        MyDrawChangesAndClear();

        if (ExtraTimeNotOver() && (--n > 0)) {
            /* lagging, catch up */

            if (n > 8) {
                /* emulation not fast enough */
                n = 8;
                CurEmulatedTime = OnTrueTime - n;
            }

            EmVideoDisable = trueblnr;

            do {
                DoEmulateOneTick();
                ++CurEmulatedTime;
            } while (ExtraTimeNotOver()
                     && (--n > 0));

            EmVideoDisable = falseblnr;
        }

        EmLagTime = n;
    }
}

void runTick(CFRunLoopTimerRef timer, void *info) {
    if (SpeedStopped) return;

    UpdateTrueEmulatedTime();
    OnTrueTime = TrueEmulatedTime;
    RunEmulatedTicksToTrueTime();
}

#if 0
#pragma mark -
#pragma mark Misc
#endif



#if 0
#pragma mark -
#pragma mark Floppy Driver
#endif

//GLOBALFUNC si4b vSonyRead(void *Buffer, ui4b Drive_No, ui5b Sony_Start, ui5b *Sony_Count)
//{
//    return [[VirtualDiskDriveController sharedInstance] readFromDrive:Drive_No start:Sony_Start count:Sony_Count buffer:Buffer];
//}
//
//GLOBALFUNC si4b vSonyWrite(void *Buffer, ui4b Drive_No, ui5b Sony_Start, ui5b *Sony_Count)
//{
//    return [[VirtualDiskDriveController sharedInstance] writeToDrive:Drive_No start:Sony_Start count:Sony_Count buffer:Buffer];
//}

#define To_tMacErr(result) ((tMacErr)(ui4b)(result))

GLOBALFUNC si4b vSonyGetSize(ui4b Drive_No, ui5b *Sony_Count) {
    return [[VirtualDiskDriveController sharedInstance] sizeOfDrive:Drive_No count:Sony_Count];
}

GLOBALFUNC si4b vSonyEject(ui4b Drive_No) {
    return [[VirtualDiskDriveController sharedInstance] ejectDrive:Drive_No] ? 0 : -1;
}

GLOBALFUNC tMacErr vSonyTransfer(blnr IsWrite, ui3p Buffer,
                                 tDrive Drive_No, ui5r Sony_Start, ui5r Sony_Count,
                                 ui5r *Sony_ActCount) {
    return To_tMacErr([[VirtualDiskDriveController sharedInstance] sonyTransfer:Drive_No isWrite:IsWrite start:Sony_Start count:Sony_Count actCount:Sony_ActCount buffer:Buffer]);
}

#ifdef IncludeSonyGetName
GLOBALFUNC si4b vSonyGetName(ui4b Drive_No, ui4b *r) {
    NSString *drvName = [[VirtualDiskDriveController sharedInstance] nameOfDrive:Drive_No];
    OSErr err = -1;
    ui4b bufNum;
    NSData *macRomanDrvName;

    if (drvName) {
        macRomanDrvName = [drvName dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
        err = PbufNew([macRomanDrvName length], &bufNum);

        if (err == noErr) {
            [macRomanDrvName getBytes:PbufDat[bufNum]];
            *r = bufNum;
        }
    }

    return err;
}

#endif

#ifdef IncludeSonyNew
GLOBALFUNC si4b vSonyEjectDelete(ui4b Drive_No) {
    return [[VirtualDiskDriveController sharedInstance] ejectAndDeleteDrive:Drive_No] ? 0 : -1;
}

#endif
#if 0
#pragma mark -
#pragma mark Parameter Buffers
#endif

#if IncludePbufs
GLOBALFUNC si4b PbufNew(ui5b count, ui4b *r) {
    ui4b i;
    void *p;
    si4b err = -1;

    if (FirstFreePbuf(&i)) {
        p = calloc(1, count);

        if (p != NULL) {
            *r = i;
            PbufDat[i] = p;
            PbufNewNotify(i, count);

            err = noErr;
        }
    }

    return err;
}

GLOBALPROC PbufDispose(ui4b i) {
    free(PbufDat[i]);
    PbufDisposeNotify(i);
}

LOCALPROC UnInitPbufs(void) {
    si4b i;

    for (i = 0; i < NumPbufs; ++i) {
        if (PbufIsAllocated(i)) {
            PbufDispose(i);
        }
    }
}

GLOBALPROC PbufTransfer(void *Buffer, ui4b i, ui5b offset, ui5b count, blnr IsWrite) {
    void *p = ((ui3p)PbufDat[i]) + offset;

    if (IsWrite) {
        (void)memcpy(p, Buffer, count);
    }
    else {
        (void)memcpy(Buffer, p, count);
    }
}

#endif /* if IncludePbufs */
