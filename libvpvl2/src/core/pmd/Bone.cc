/* ----------------------------------------------------------------- */
/*                                                                   */
/*  Copyright (c) 2010-2012  hkrn                                    */
/*                                                                   */
/* All rights reserved.                                              */
/*                                                                   */
/* Redistribution and use in source and binary forms, with or        */
/* without modification, are permitted provided that the following   */
/* conditions are met:                                               */
/*                                                                   */
/* - Redistributions of source code must retain the above copyright  */
/*   notice, this list of conditions and the following disclaimer.   */
/* - Redistributions in binary form must reproduce the above         */
/*   copyright notice, this list of conditions and the following     */
/*   disclaimer in the documentation and/or other materials provided */
/*   with the distribution.                                          */
/* - Neither the name of the MMDAI project team nor the names of     */
/*   its contributors may be used to endorse or promote products     */
/*   derived from this software without specific prior written       */
/*   permission.                                                     */
/*                                                                   */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND            */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,       */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF          */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS */
/* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,          */
/* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     */
/* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON */
/* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   */
/* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    */
/* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           */
/* POSSIBILITY OF SUCH DAMAGE.                                       */
/* ----------------------------------------------------------------- */

#include "vpvl2/vpvl2.h"
#include "vpvl2/internal/util.h"
#include "vpvl2/pmd/Bone.h"

namespace
{

using namespace vpvl2::pmd;

#pragma pack(push, 1)

struct BoneUnit {
    uint8_t name[Bone::kNameSize];
    int16_t parentBoneID;
    int16_t childBoneID;
    uint8_t type;
    int16_t targetBoneID;
    float position[3];
};

struct IKUnit
{
    int16_t rootBoneID;
    int16_t targetBoneID;
    uint8_t nlinks;
    uint16_t niterations;
    float angle;
};

#pragma pack(pop)

}

namespace vpvl2
{
namespace pmd
{

struct Bone::IKConstraint {
    Array<Bone *> effectors;
    IBone *root;
    IBone *target;
    int niterations;
    float angle;
};

const int Bone::kNameSize;
const int Bone::kCategoryNameSize;

Bone::Bone(IEncoding *encodingRef)
    : m_encodingRef(encodingRef),
      m_name(0),
      m_parentBoneRef(0),
      m_targetBoneRef(0),
      m_childBoneRef(0),
      m_constraint(0),
      m_fixedAxis(kZeroV3),
      m_origin(kZeroV3),
      m_offset(kZeroV3),
      m_localPosition(kZeroV3),
      m_rotation(Quaternion::getIdentity()),
      m_worldTransform(Transform::getIdentity()),
      m_localTransform(Transform::getIdentity()),
      m_type(kUnknown),
      m_index(-1),
      m_parentBoneIndex(0),
      m_targetBoneIndex(0),
      m_childBoneIndex(0),
      m_simulated(false)
{
}

Bone::~Bone()
{
    delete m_name;
    m_name = 0;
    delete m_constraint;
    m_constraint = 0;
    m_encodingRef = 0;
    m_parentBoneRef = 0;
    m_childBoneRef = 0;
    m_targetBoneRef = 0;
    m_index = -1;
    m_parentBoneIndex = 0;
    m_childBoneIndex = 0;
    m_targetBoneIndex = 0;
    m_type = kUnknown;
    m_fixedAxis.setZero();
    m_origin.setZero();
    m_offset.setZero();
    m_localPosition.setZero();
    m_worldTransform.setIdentity();
    m_localTransform.setIdentity();
    m_simulated = false;
}

bool Bone::preparseBones(uint8_t *&ptr, size_t &rest, Model::DataInfo &info)
{
    size_t size;
    if (!internal::size16(ptr, rest, size) || size * sizeof(BoneUnit) > rest) {
        return false;
    }
    info.bonesCount = size;
    info.bonesPtr = ptr;
    internal::readBytes(size * sizeof(BoneUnit), ptr, rest);
    return true;
}

bool Bone::preparseIKConstraints(uint8_t *&ptr, size_t &rest, Model::DataInfo &info)
{
    size_t size;
    if (!internal::size16(ptr, rest, size)) {
        return false;
    }
    info.IKConstraintsCount = size;
    info.IKConstraintsPtr = ptr;
    IKUnit unit;
    size_t unitSize = 0;
    for (size_t i = 0; i < size; i++) {
        if (sizeof(unit) > rest) {
            return false;
        }
        internal::getData(ptr, unit);
        unitSize = sizeof(unit) + unit.nlinks * sizeof(uint16_t);
        if (unitSize > rest) {
            return false;
        }
        internal::readBytes(unitSize, ptr, rest);
    }
    return true;
}

bool Bone::loadBones(const Array<Bone *> &bones)
{
    const int nbones = bones.count();
    for (int i = 0; i < nbones; i++) {
        Bone *bone = bones[i];
        bone->m_index = i;
        const int parentBoneIndex = bone->m_parentBoneIndex;
        if (parentBoneIndex >= 0) {
            if (parentBoneIndex >= nbones) {
                return false;
            }
            else {
                Bone *parent = bones[parentBoneIndex];
                bone->m_offset -= parent->m_origin;
                bone->m_parentBoneRef = parent;
            }
        }
        const int targetBoneIndex = bone->m_targetBoneIndex;
        if (targetBoneIndex >= 0) {
            if (targetBoneIndex >= nbones)
                return false;
            else
                bone->m_targetBoneRef = bones[targetBoneIndex];
        }
        const int childBoneIndex = bone->m_childBoneIndex;
        if (childBoneIndex >= 0) {
            if (childBoneIndex >= nbones)
                return false;
            else
                bone->m_childBoneRef = bones[childBoneIndex];
        }
    }
    return true;
}

void Bone::readIKConstraint(const uint8_t *data, const Array<Bone *> &bones, size_t &size)
{
    IKUnit unit;
    internal::getData(data, unit);
    int nlinks = unit.nlinks, nbones = bones.count();
    int targetIndex = unit.targetBoneID;
    int rootIndex = unit.rootBoneID;
    if (internal::checkBound(targetIndex, 0, nbones) && internal::checkBound(rootIndex, 0, nbones)) {
        uint8_t *ptr = const_cast<uint8_t *>(data + sizeof(unit));
        Array<Bone *> effectors;
        for (int i = 0; i < nlinks; i++) {
            int boneIndex = internal::readUnsignedIndex(ptr, sizeof(uint16_t));
            if (internal::checkBound(boneIndex, 0, nbones)) {
                Bone *bone = bones[boneIndex];
                effectors.add(bone);
            }
            ptr += sizeof(uint16_t);
        }
        Bone *rootBone = bones[rootIndex], *targetBone = bones[targetIndex];
        IKConstraint *constraint = rootBone->m_constraint = new IKConstraint();
        constraint->effectors.copy(effectors);
        constraint->root = rootBone;
        constraint->target = targetBone;
        constraint->niterations = unit.niterations;
        constraint->angle = unit.angle;
    }
    size = sizeof(unit) + sizeof(uint16_t) * nlinks;
}

size_t Bone::estimateTotalSize(const Array<Bone *> &bones, const Model::DataInfo &info)
{
    const int nbones = bones.count();
    size_t size = 0;
    for (int i = 0; i < nbones; i++) {
        Bone *bone = bones[i];
        size += bone->estimateBoneSize(info);
        size += bone->estimateIKConstraintsSize(info);
    }
    return size;
}

void Bone::readBone(const uint8_t *data, const Model::DataInfo & /* info */, size_t &size)
{
    BoneUnit unit;
    internal::getData(data, unit);
    m_name = m_encodingRef->toString(unit.name, IString::kShiftJIS, kNameSize);
    m_childBoneIndex = unit.childBoneID;
    m_parentBoneIndex = unit.parentBoneID;
    m_targetBoneIndex = unit.targetBoneID;
    m_type = static_cast<Type>(unit.type);
    internal::setPosition(unit.position, m_origin);
    m_offset = m_origin;
    size = sizeof(unit);
}

size_t Bone::estimateBoneSize(const Model::DataInfo & /* info */) const
{
    size_t size = 0;
    size += sizeof(BoneUnit);
    return size;
}

size_t Bone::estimateIKConstraintsSize(const Model::DataInfo & /* info */) const
{
    size_t size = 0;
    if (m_constraint) {
        size += sizeof(IKUnit);
        size += sizeof(uint16_t) * m_constraint->effectors.count();
    }
    return size;
}

void Bone::write(uint8_t *data, const Model::DataInfo & /* info */) const
{
    BoneUnit unit;
    unit.childBoneID = m_childBoneIndex;
    unit.parentBoneID = m_parentBoneIndex;
    uint8_t *name = m_encodingRef->toByteArray(m_name, IString::kShiftJIS);
    internal::copyBytes(unit.name, name, sizeof(unit.name));
    m_encodingRef->disposeByteArray(name);
    internal::getPosition(m_origin, unit.position);
    unit.targetBoneID = m_targetBoneIndex;
    unit.type = m_type;
    internal::copyBytes(data, reinterpret_cast<const uint8_t *>(&unit), sizeof(unit));
}

void Bone::performTransform()
{
    m_worldTransform.setIdentity();
    if (m_type == kUnderRotate && m_targetBoneRef) {
        const Quaternion &rotation = m_rotation * m_targetBoneRef->rotation();
        m_worldTransform.setRotation(rotation);
    }
    else if (m_type == kFollowRotate && m_childBoneRef) {
        const Scalar coef(m_targetBoneIndex * 0.01f);
        const Quaternion &rotation = Quaternion::getIdentity().slerp(m_rotation, coef);
        m_worldTransform.setRotation(rotation);
    }
    else {
        m_worldTransform.setRotation(m_rotation);
    }
    m_worldTransform.setOrigin(m_offset + m_localPosition);
    if (m_parentBoneRef) {
        m_worldTransform = m_parentBoneRef->worldTransform() * m_worldTransform;
    }
    getLocalTransform(m_localTransform);
}

void Bone::solveInverseKinematics()
{
}

const IString *Bone::name() const
{
    return m_name;
}

int Bone::index() const
{
    return m_index;
}

IBone *Bone::parentBone() const
{
    return m_parentBoneRef;
}

IBone *Bone::targetBone() const
{
    return m_targetBoneRef;
}

const Transform &Bone::worldTransform() const
{
    return m_worldTransform;
}

const Transform &Bone::localTransform() const
{
    return m_localTransform;
}

void Bone::getLocalTransform(Transform &world2LocalTransform) const
{
    getLocalTransform(m_worldTransform, world2LocalTransform);
}

void Bone::getLocalTransform(const Transform &worldTransform, Transform &output) const
{
    output = worldTransform * Transform(Matrix3x3::getIdentity(), -m_origin);
}

void Bone::setLocalTransform(const Transform &value)
{
    m_localTransform = value;
}

const Vector3 &Bone::origin() const
{
    return m_origin;
}

const Vector3 Bone::destinationOrigin() const
{
    return m_parentBoneRef ? m_parentBoneRef->origin() : kZeroV3;
}

const Vector3 &Bone::localPosition() const
{
    return m_localPosition;
}

const Quaternion &Bone::rotation() const
{
    return m_rotation;
}

void Bone::getEffectorBones(Array<IBone *> &value) const
{
    if (m_constraint) {
        const Array<Bone *> &effectors = m_constraint->effectors;
        const int nbones = effectors.count();
        for (int i = 0; i < nbones; i++) {
            IBone *bone = effectors[i];
            value.add(bone);
        }
    }
}

void Bone::setLocalPosition(const Vector3 &value)
{
    m_localPosition = value;
}

void Bone::setRotation(const Quaternion &value)
{
    m_rotation = value;
}

bool Bone::isMovable() const
{
    return m_type == kRotateAndMove;
}

bool Bone::isRotateable() const
{
    return m_type == kRotate || m_type == kRotateAndMove;
}

bool Bone::isVisible() const
{
    return m_type != kInvisible;
}

bool Bone::isInteractive() const
{
    return isRotateable();
}

bool Bone::hasInverseKinematics() const
{
    return m_type == kIKDestination;
}

bool Bone::hasFixedAxes() const
{
    return m_type == kTwist;
}

bool Bone::hasLocalAxes() const
{
    bool hasFinger = m_name->contains(m_encodingRef->stringConstant(IEncoding::kFinger));
    bool hasArm = m_name->endsWith(m_encodingRef->stringConstant(IEncoding::kArm));
    bool hasElbow = m_name->endsWith(m_encodingRef->stringConstant(IEncoding::kElbow));
    bool hasWrist = m_name->endsWith(m_encodingRef->stringConstant(IEncoding::kWrist));
    return hasFinger || hasArm || hasElbow || hasWrist;
}

const Vector3 &Bone::fixedAxis() const
{
    return m_fixedAxis;
}

void Bone::getLocalAxes(Matrix3x3 &value) const
{
    if (hasLocalAxes()) {
        const Vector3 &axisX = (m_childBoneRef->origin() - origin()).normalized();
        Vector3 tmp1 = axisX;
        if (m_name->startsWith(m_encodingRef->stringConstant(IEncoding::kLeft)))
            tmp1.setY(-axisX.y());
        else
            tmp1.setX(-axisX.x());
        const Vector3 &axisZ = axisX.cross(tmp1).normalized();
        Vector3 tmp2 = axisX;
        tmp2.setZ(-axisZ.z());
        const Vector3 &axisY = tmp2.cross(-axisX).normalized();
        value[0] = axisX;
        value[1] = axisY;
        value[2] = axisZ;
    }
    else {
        value.setIdentity();
    }
}

void Bone::setSimulated(bool value)
{
    m_simulated = value;
}

}
}
