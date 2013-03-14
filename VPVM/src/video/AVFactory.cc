#include "AVFactory.h"

#ifdef VPVM_ENABLE_VIDEO
#include "video/AudioDecoder.h"
#include "video/VideoEncoder.h"
#endif

namespace vpvm
{

AVFactory::AVFactory(QObject *parent)
    : QObject(parent),
      m_parent(parent)
{
}

bool AVFactory::isSupported() const
{
    return true;
}

IAudioDecoder *AVFactory::createAudioDecoder() const
{
#ifdef VPVM_ENABLE_VIDEO
    return new AudioDecoder(m_parent);
#else
    return 0;
#endif
}

IVideoEncoder *AVFactory::createVideoEncoder() const
{
#ifdef VPVM_ENABLE_VIDEO
    return new VideoEncoder(m_parent);
#else
    return 0;
#endif
}

} /* namespace vpvm */
