from pkgutil import extend_path
__path__ = extend_path(__path__, __name__)
import sys
import os
sys.path.append(os.getcwd() + "/trick.zip/trick")

import _sim_services
from sim_services import *

# create "all_cvars" to hold all global/static vars
all_cvars = new_cvar_list()
combine_cvars(all_cvars, cvar)
cvar = None

# /home/cody/trick_sims/SIM_BLDC_Motor/S_source.hh
import _ma9557597abdbd3daf7ecce6896a576f7
combine_cvars(all_cvars, cvar)
cvar = None

# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/httpMethods/bldc_http_handlers.h
import _med004e9567e72749b6d50f5dbf2a207f
combine_cvars(all_cvars, cvar)
cvar = None

# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/httpMethods/handle_HTTP_GET_php.h
import _mcc1eb08e3f94331d1812c71b9fae1372
combine_cvars(all_cvars, cvar)
cvar = None

# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/include/bldc.h
import _m2cd2ea3140437a6e84b87f64e5b5d405
combine_cvars(all_cvars, cvar)
cvar = None

# /home/cody/trick_sims/SIM_BLDC_Motor/S_source.hh
from ma9557597abdbd3daf7ecce6896a576f7 import *
# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/httpMethods/bldc_http_handlers.h
from med004e9567e72749b6d50f5dbf2a207f import *
# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/httpMethods/handle_HTTP_GET_php.h
from mcc1eb08e3f94331d1812c71b9fae1372 import *
# /home/cody/trick_sims/SIM_BLDC_Motor/models/bldc/include/bldc.h
from m2cd2ea3140437a6e84b87f64e5b5d405 import *

# S_source.hh
import _ma9557597abdbd3daf7ecce6896a576f7
from ma9557597abdbd3daf7ecce6896a576f7 import *

import _top
import top

import _swig_double
import swig_double

import _swig_int
import swig_int

import _swig_ref
import swig_ref

from shortcuts import *

from exception import *

cvar = all_cvars

