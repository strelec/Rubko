#!/bin/bash

coffee -c .private/core.coffee

:> js.js
closure --charset utf-8 jquery/jquery.js >> js.js
closure --charset utf-8 core.js >> js.js
closure --charset utf-8 jquery/iframize.js >> js.js
closure --charset utf-8 jquery/translate.js >> js.js
closure --charset utf-8 .private/core.js >> js.js