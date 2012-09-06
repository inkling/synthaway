#
# CMakeLists.txt
# synthaway
#
# Copyright (c) 2012 Inkling Systems, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

CMAKE_MINIMUM_REQUIRED (VERSION 2.8)

PROJECT (sythesize-away)

SET(CMAKE_DISABLE_SOURCE_CHANGES ON)
SET(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
SET(CMAKE_BUILD_TYPE None)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -O0 -g -fno-rtti -fcolor-diagnostics -Wno-c++11-extensions -Wunused-variable")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -g -fno-rtti")

FIND_PACKAGE(LLVM REQUIRED)

ADD_DEFINITIONS(${LLVM_DEFINITIONS})
INCLUDE_DIRECTORIES(${LLVM_INCLUDE_DIRS} .)
LINK_DIRECTORIES(${LLVM_LIBRARY_DIRS})
LLVM_MAP_COMPONENTS_TO_LIBRARIES(REQ_LLVM_LIBRARIES arminfo cellspuinfo cppbackendinfo debuginfo hexagoninfo mblazeinfo mipsinfo msp430info nvptxinfo powerpcinfo sparcinfo x86info xcoreinfo armdesc cellspudesc hexagondesc mblazedesc mipsdesc msp430desc nvptxdesc powerpcdesc sparcdesc x86desc xcoredesc armasmparser asmparser mblazeasmparser mcparser mipsasmparser x86asmparser)

SET(CLANG_LIBRARIES clangAnalysis clangAST clangBasic clangDriver clangEdit clangFrontend clangLex clangParse clangRewriteCore clangSema clangSerialization clangTooling)

SET(sources synthaway.cpp)
ADD_EXECUTABLE (synthaway ${sources})
TARGET_LINK_LIBRARIES (synthaway ${REQ_LLVM_LIBRARIES} ${CLANG_LIBRARIES})

INSTALL(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/synthaway DESTINATION bin)
INSTALL(PROGRAMS extract-xcodebuild-log.py RENAME extract-xcodebuild-log DESTINATION bin)

ENABLE_TESTING()
SET(TEST_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/tests/run-test.sh)
SET(BUILT_SYNTHAWAY ${PROJECT_BINARY_DIR}/synthaway)

ADD_TEST(NAME AddUnderscoreTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/add-underscore.m)
ADD_TEST(NAME AutoSynthesisDisallowedTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/auto-synthesis-disallowed.m)
ADD_TEST(NAME BasicTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/basic.m)
ADD_TEST(NAME BlockTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/block.m)
ADD_TEST(NAME CompoundDirectiveTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/compound-directive.m)
ADD_TEST(NAME ExplicitIvarTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/explicit-ivar.m)
ADD_TEST(NAME IdentityTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/identity.m)
ADD_TEST(NAME LinkedListTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/linkedlist.m)
ADD_TEST(NAME MixedTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/mixed.m)
ADD_TEST(NAME NameCollisionTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/name-collision.m)
ADD_TEST(NAME NameDivergenceTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/name-divergence.m)
ADD_TEST(NAME ObjCXXTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/objcxx.mm)
ADD_TEST(NAME OverriddingGetterSetterTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/overridding-getter-setter.m)
ADD_TEST(NAME ProtocolPropertyTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/protocol-property.m)
ADD_TEST(NAME TypeDivergenceTest COMMAND ${TEST_SCRIPT} ${BUILT_SYNTHAWAY} ${CMAKE_CURRENT_SOURCE_DIR}/tests/type-divergence.m)
