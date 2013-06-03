# -*- coding: utf-8 -*-

import os

import bson
import pymongo
from suq import monpyjama

from souk import contexts
from souk.model import *


db = pymongo.Connection().souk_passim
monpyjama.Wrapper.db = db

ctx = contexts.null_ctx
ObjectId = bson.objectid.ObjectId
