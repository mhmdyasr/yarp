// -*- mode:C++; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

/*
* Copyright (C) 2008 RobotCub Consortium
* Authors: Lorenzo Natale and Ugo Pattacini
* CopyPolicy: Released under the terms of the GNU GPL v2.0.
*/

#ifndef __YARPCARTESIANCONTROLINTERFACES__
#define __YARPCARTESIANCONTROLINTERFACES__

#include <yarp/dev/DeviceDriver.h>

#include <yarp/sig/Vector.h>

/*! \file CartesianController.h define control board standard interfaces*/

namespace yarp {
    namespace dev {
        class ICartesianControl;
    }
}


/**
 * @ingroup dev_icartesianControl
 *
 * Interface for a cartesian controller.
 */
class yarp::dev::ICartesianControl
{
public:
    /**
     * Destructor.
     */
    virtual ~ICartesianControl() {}

    /**
    * Move the end effector to a specified pose (position
    * and orientation) in cartesian space.
    * @param xd: a 3-d vector which contains the desired position x,y,z
    * @param od: a 4-d vector which contains the desired orientation
    * using axis-angle representation (xa, ya, za, theta).
    * @return true/false on success/failure.
    */
    virtual bool goToPose(const yarp::sig::Vector &xd, const yarp::sig::Vector &od)=0;

    /**
    * Move the end effector to a specified position in cartesian space, 
    * ignore the orientation.
    * @param xd: a 3-d vector which contains the desired position x,y,z
    * @return true/false on success/failure.
    */
    virtual bool goToPosition(const yarp::sig::Vector &xd)=0;

    /**
    * Get the current pose.
    * @param x: a 3-d vector which is filled with the actual position x,y,z (meters)
    * @param od: a 4-d vector which is filled with the actual orientation
    * using axis-angle representation xa, ya, za, theta (meters and degrees).
    * @return true/false on success/failure.
    */
    virtual bool getPose(yarp::sig::Vector &x, yarp::sig::Vector &o)=0;

    /**
    * Get the current DOF configuration of the limb.
    * @param dof: a vector which is filled with the actual DOF 
    *           configuration.
    * \note The vector lenght is equal to the number of limb's 
    *       joints; each vector's position is filled with 1 if the
    *       associated joint is controlled (i.e. it is a DOF), 0
    *       otherwise.
    * @return true/false on success/failure.
    */
    virtual bool getDOF(yarp::sig::Vector &dof)=0;

    /**
    * Set a new DOF configuration for the limb.
    * @param newDof: a vector which contains the new DOF 
    *            configuration.
    * @param curDof: a vector which is filled with the actual DOF 
    *              configuration (it may differ from newDof due to
    *              the presence of some internal limb's
    *              constraints).
    * \note Eeach vector's position shall contain 1 if the 
    *       associated joint has to be controlled, 0 otherwise.
    * @return true/false on success/failure.
    */
    virtual bool setDOF(const yarp::sig::Vector &newDof, yarp::sig::Vector &curDof)=0;

    /** Check if the current trajectory is terminated. Non blocking.
    * @return true if the trajectory is terminated, false otherwise
    */
    virtual bool checkMotionDone(bool *f)=0;

    /**
    * Set the duration of the trajectory.
    * @param t: time (seconds).
    * @return true/false on success/failure.
    */
    virtual bool setTrajTime(const double t)=0;

    /**
    * Get the current trajectory duration.
    * @param t: time (seconds).
    * @return true/false on success/failure.
    */
    virtual bool getTrajTime(double *t)=0;
};

#endif

