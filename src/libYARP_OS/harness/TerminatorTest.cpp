// -*- mode:C++; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

/*
 * Copyright (C) 2006 Giorgio Metta
 * CopyPolicy: Released under the terms of the GNU GPL v2.0.
 *
 */

#include <yarp/os/Terminator.h>
#include <yarp/NameServer.h>
#include <yarp/os/Network.h>
#include <yarp/os/Time.h>

#include "TestList.h"

using namespace yarp;
using namespace yarp::os;

class TerminatorTest : public UnitTest {
public:
    virtual String getName() { return "TerminatorTest"; }

    virtual void testTerminationPair() {
        report(0,"checking terminator connection");
        Network::setLocalMode(true);

        ACE_OS::printf("registering port name: ");
        Terminee terminee("/tmp/quit");
        if (terminee.isOk())
            ACE_OS::printf("ok\n");
        else {
            ACE_OS::printf("failed\n");
            report(1,"failed to set terminator socket");
        }
        Time::delay(1.4);

        ACE_OS::printf("sending quit message: ");
        if (Terminator::terminateByName("/tmp/quit"))
            ACE_OS::printf("ok\n");
        else {
            ACE_OS::printf("failed\n");
            report(1,"failed to set termination connection");
        }
        Time::delay(0.5);

        ACE_OS::printf("quit flag was set properly: ");
        if (!terminee.mustQuit()) {
            ACE_OS::printf("failed\n");
            report(1,"failed to receive the quit message");
        }
        else {
            ACE_OS::printf("ok\n");
        }
    }

    virtual void runTests() {
        testTerminationPair();
    }
};

static TerminatorTest theTerminatorTest;

UnitTest& getTerminatorTest() {
    return theTerminatorTest;
}

