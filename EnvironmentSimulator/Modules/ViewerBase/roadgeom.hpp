/*
 * esmini - Environment Simulator Minimalistic
 * https://github.com/esmini/esmini
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) partners of Simulation Scenarios
 * https://sites.google.com/view/simulationscenarios
 */

#ifndef ROADGEOM_HPP_
#define ROADGEOM_HPP_

#include <osg/PositionAttitudeTransform>
#include <osg/Texture2D>
#include <osg/Group>
#include <osg/Geometry>
#include <osg/Material>
#include "RoadManager.hpp"

class RoadGeom
{
    typedef struct
    {
        osg::ref_ptr<osg::Material> material;
        double                      friction;
    } FrictionDetails;  // could be multiple of these per lane

public:
    osg::ref_ptr<osg::Group>     root_;
    osg::ref_ptr<osg::Group>     rm_group_;
    osg::ref_ptr<osg::Vec4Array> color_asphalt_ = new osg::Vec4Array;

    RoadGeom(roadmanager::OpenDrive* odr, osg::Vec3d origin);
    int  AddRoadMarks(roadmanager::Lane* lane, osg::Group* group);
    void AddRoadMarkGeom(osg::ref_ptr<osg::Vec3Array> vertices, osg::ref_ptr<osg::DrawElementsUInt> indices, roadmanager::RoadMarkColor color);
    osg::ref_ptr<osg::Texture2D> ReadTexture(std::string filename);
    void                         AddRoadMaterialInList(osg::ref_ptr<osg::Material> material, double friction);
    std::vector<FrictionDetails> GetRoadMaterialList();
    const osg::Vec4              GetFrictionColor(const double friction);

private:
    std::vector<FrictionDetails> material_friction_list_;
};

#endif  // ROADGEOM_HPP_
