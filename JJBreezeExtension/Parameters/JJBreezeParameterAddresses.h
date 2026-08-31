#pragma once

#include <AudioToolbox/AUParameters.h>

typedef NS_ENUM(AUParameterAddress, JJBreezeParameterAddress) {
    pitchL = 0,
    pitchR,
    delayL,
    delayR,
    focus,
    mix,
    vibratoRate,
    vibratoDepth,
    vibratoMix,
    warmthTone,
    warmthDrive,
    warmthBody,
    warmthMix,
    shiftOn,
    vibratoOn,
    warmthOn
};
