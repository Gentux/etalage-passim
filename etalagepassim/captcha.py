# -*- coding: utf-8 -*-


# Etalage-Passim -- Customization of Etalage for Passim
# By: Emmanuel Raviart <eraviart@easter-eggs.com>
#
# Copyright (C) 2011, 2012, 2013 Easter-eggs
# http://gitorious.org/passim/etalage-passim
#
# This file is part of Etalage-Passim.
#
# Etalage-Passim is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Etalage-Passim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""Google reCaptcha submit helper"""


import logging

from biryani.baseconv import cleanup_line, pipe, not_none
from recaptcha.client import captcha

from . import conf

log = logging.getLogger(__name__)


def submit(req):
    data = req.params
    recaptcha_challenge_field, error = pipe(cleanup_line, not_none)(data['recaptcha_challenge_field'])
    if error:
        # An empty recaptcha_challenge_field means there is a problem with Google reCaptcha service
        # don't return an error
        return captcha.RecaptchaResponse(is_valid=True)
    recaptcha_response_field, error = pipe(cleanup_line, not_none)(data['recaptcha_response_field'])
    if error:
        return captcha.RecaptchaResponse(is_valid=False, error_code='incorrect-captcha-sol')

    response = captcha.submit(
        recaptcha_challenge_field,
        recaptcha_response_field,
        conf['recaptcha.private_key'],
        req.remote_addr)

    if not response.is_valid and \
        response.error_code in ['invalid-site-private-key', 'invalid-request-cookie', 'recaptcha-not-reachable']:
        log.debug('reCaptcha Google service error: {}'.format(response.error_code))
        return captcha.RecaptchaResponse(is_valid=True)

    return response
