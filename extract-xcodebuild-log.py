#!/usr/bin/python
#
# extract-xcodebuild-log.py: Extract xcodebuild log to compile_commands.json
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

import re
import sys
import json

# regex for finding the start of compiler invocation
compileCmd = re.compile("^CompileC")

# regex for finding clang
clangCmd = re.compile("\s*(.*clang .+)")

# regex for removing the use of precompiled headers
removePCH = re.compile(" -include .+?\.pch")

# regex for inserting additional clang options, not used for now
insertStdarg = re.compile("/clang ")

# regex for finding the source file, in two flavors
mainFile = re.compile("-c \"(.+?)\"")
mainFileUnquoted = re.compile(" -c (.+?) -o")

# regex for finding the directory
# TODO: Use Python built-in library
dirMatch = re.compile("(.+)/.+")

entries = []
criteria = []

if len(sys.argv) > 1:
  for a in sys.argv[1:]:
    criteria += [re.compile(a)]

while 1:
  line = sys.stdin.readline()
  if not line:
    break
  line = line.strip()
  f = compileCmd.search(line)
  if f:
    while 1:
      line = sys.stdin.readline()      
      if not line:
        break
      line = line.strip()
      f = clangCmd.search(line)
      if f:
        cmd = f.group(1)
        
        noPCHCmd = removePCH.sub("", cmd)
        
        insertStdargCmd = insertStdarg.sub("/clang ", noPCHCmd)
        
        mf = mainFile.search(cmd)
        if not mf:
          mf = mainFileUnquoted.search(cmd)
        
        d = dirMatch.search(mf.group(1))

        match = True

        if len(criteria) > 0:
          match = False
          for p in criteria:
            if p.search(mf.group(1)):
              match = True
              break
            
        if match:
          obj = {"directory":d.group(1), "command":insertStdargCmd, "file":mf.group(1)}
          entries += [obj]
        
        break
        
print json.dumps(entries, sort_keys=True, indent=4)
