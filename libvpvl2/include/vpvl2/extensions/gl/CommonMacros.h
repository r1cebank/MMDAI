/* ----------------------------------------------------------------- */
/*                                                                   */
/*  Copyright (c) 2010-2013  hkrn                                    */
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

#pragma once
#ifndef VPVL2_EXTENSIONS_GL_COMMONMACROS_H_
#define VPVL2_EXTENSIONS_GL_COMMONMACROS_H_

#include <vpvl2/config.h>
#if defined(VPVL2_LINK_GLEW)
#if defined(_MSC_VER)
#include <Windows.h>
//#if !defined(BUILD_SHARED_LIBS)
#define GLEW_STATIC
//#endif /* BUILD_SHARED_LIBS */
#endif /* _MSC_VER */
#include <GL/glew.h>
#elif defined(__APPLE__)
#if defined(VPVL2_ENABLE_GLES2)
#include <OpenGLES2/gl2.h>
#include <OpenGLES2/gl2ext.h>
#define GLEW_ARB_vertex_array_object GL_OES_vertex_array_object
#define GLEW_ARB_depth_buffer_float 0
#else /* VPVL2_ENABLE_GLES2 */
#include <OpenGL/gl3.h>
#include <OpenGL/gl3ext.h>
#define GLEW_ARB_vertex_array_object GL_ARB_vertex_array_object
#define GLEW_ARB_depth_buffer_float GL_ARB_depth_buffer_float
#endif /* __APPLE__ */
#elif defined(VPVL2_ENABLE_GLES2)
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#define GLEW_ARB_vertex_array_object GL_OES_vertex_array_object
#define GLEW_ARB_depth_buffer_float 0
#else /* VPVL2_ENABLE_GLES2 */
#include <GL/gl.h>
#include <GL/glext.h>
#define GLEW_ARB_vertex_array_object GL_ARB_vertex_array_object
#define GLEW_ARB_depth_buffer_float GL_ARB_depth_buffer_float
#endif /* VPVL2_LINK_GLEW */

#endif
