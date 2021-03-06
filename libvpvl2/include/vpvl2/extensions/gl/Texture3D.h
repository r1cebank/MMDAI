/**

 Copyright (c) 2010-2013  hkrn

 All rights reserved.

 Redistribution and use in source and binary forms, with or
 without modification, are permitted provided that the following
 conditions are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the following
   disclaimer in the documentation and/or other materials provided
   with the distribution.
 - Neither the name of the MMDAI project team nor the names of
   its contributors may be used to endorse or promote products
   derived from this software without specific prior written
   permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

*/

#pragma once
#ifndef VPVL2_EXTENSIONS_GL_TEXTURE3D_H_
#define VPVL2_EXTENSIONS_GL_TEXTURE3D_H_

#include <vpvl2/ITexture.h>
#include <vpvl2/extensions/gl/BaseTexture.h>

namespace vpvl2
{
namespace extensions
{
namespace gl
{

class Texture3D VPVL2_DECL_FINAL : public BaseTexture {
public:
    static const GLenum kGL_TEXTURE_3D = 0x806F;

    Texture3D(const IApplicationContext::FunctionResolver *resolver, const BaseSurface::Format &format, const Vector3 &size, GLenum sampler)
        : BaseTexture(resolver, format, size, sampler),
          texImage3D(reinterpret_cast<PFNGLTEXIMAGE3DPROC>(resolver->resolveSymbol("glTexImage3D"))),
          texSubImage3D(reinterpret_cast<PFNGLTEXSUBIMAGE3DPROC>(resolver->resolveSymbol("glTexSubImage3D"))),
          texStorage3D(reinterpret_cast<PFNGLTEXSTORAGE3DPROC>(resolver->resolveSymbol("glTexStorage3D"))),
          m_hasTextureStorage(resolver->hasExtension("ARB_texture_storage"))
    {
        m_format.target = kGL_TEXTURE_3D;
    }
    ~Texture3D() {
    }

    void fillPixels(const void *pixels) {
        if (m_hasTextureStorage) {
            texStorage3D(m_format.target, 1, m_format.internal, GLsizei(m_size.x()), GLsizei(m_size.y()), GLsizei(m_size.z()));
            write(pixels);
        }
        else {
            allocate(pixels);
        }
    }
    void allocate(const void *pixels) {
        texImage3D(m_format.target, 0, m_format.internal, GLsizei(m_size.x()), GLsizei(m_size.y()), GLsizei(m_size.z()), 0, m_format.external, m_format.type, pixels);
    }
    void write(const void *pixels) {
        texSubImage3D(m_format.target, 0, 0, 0, 0, GLsizei(m_size.x()), GLsizei(m_size.y()), GLsizei(m_size.z()), m_format.external, m_format.type, pixels);
    }

private:
    typedef void (GLAPIENTRY * PFNGLTEXIMAGE3DPROC) (GLenum target, GLint level, GLint internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (GLAPIENTRY * PFNGLTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (GLAPIENTRY * PFNGLTEXSTORAGE3DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
    PFNGLTEXIMAGE3DPROC texImage3D;
    PFNGLTEXSUBIMAGE3DPROC texSubImage3D;
    PFNGLTEXSTORAGE3DPROC texStorage3D;
    const bool m_hasTextureStorage;
};

} /* namespace gl */
} /* namespace extensions */
} /* namespace vpvl2 */

#endif
