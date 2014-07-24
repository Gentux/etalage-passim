# -*- coding: utf-8 -*-

import logging

from biryani.baseconv import cleanup_line, pipe, not_none
from recaptcha.client import captcha

from . import conf, contexts

log = logging.getLogger(__name__)


def submit(req):
    ctx = contexts.Ctx(req)
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
