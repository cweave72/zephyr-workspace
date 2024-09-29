#!/bin/bash

find . \
    -path */build -prune -o \
    -name "*.[chisS]" \
    -print > cscope.files

cscope -R -k -b -i cscope.files

ctags -R .
