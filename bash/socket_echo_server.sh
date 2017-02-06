#!/bin/bash

sudo socat TCP4-LISTEN:10000,fork EXEC:cat
