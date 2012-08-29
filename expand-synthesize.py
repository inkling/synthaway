#!/usr/bin/python
#
# expand-synthesize.py: Expand compound @synthesize directives
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

outer = re.compile("(\s*@synthesize\s+\w+\s*(=\s*\w+)?)((\s*,\s*\w+\s*(=\s*\w+)?)+)\s*;")
inner = re.compile("\s*,\s*")

def expand(s):
	m = outer.search(s)
	if m:
		line = m.group(1) + inner.sub(";\n@synthesize ", m.group(3)) + ";\n"
		return line

if len(sys.argv) < 2:
	sys.stderr.write("usage: expand-synthesize.py [source file] ...\n")
	sys.exit(1)

for fn in sys.argv[1:]:
	wlines = []
	f = open(fn, "r")
	lines = f.readlines()
	
	ever = False
	for l in lines:
		e = expand(l)
		if e:
			ever = True
			wlines += [e]
		else:
			wlines += [l]

	if ever:
		f.close()
		f = open(fn, "w")
		for l in wlines:
			f.write(l)
		print("Compound @synthesize found and replaced in: %s" % fn)
