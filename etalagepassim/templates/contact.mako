## -*- coding: utf-8 -*-


## Etalage-Passim -- Customization of Etalage for Passim
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012, 2013 Easter-eggs
## http://gitorious.org/passim/etalage-passim
##
## This file is part of Etalage-Passim.
##
## Etalage-Passim is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage-Passim is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%!
import markdown

from etalagepassim import conf
%>


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
<%
    subject = _(u'Contact PASSIM : [your message subject]')
    body = _(u'''
I am [an end-user, a company...]

My e-mail address: [xxx@yyy.org]

My message: ...


''')
%>
    <h4>${_('Contact')}</h4>
    <hr>
% if data['message'] is not None:
    <div class="alert alert-success">
        <button type="button" class="close" data-dismiss="alert">&times;</button>
        ${data['message']}
    </div>
% endif
    <div class="contact-text">
        ${markdown.markdown(_(u'''
[Please click here and complete this e-mail](#input-modal).<br>
Thank you for any question, remark or enhancement proposal.
''')) | n}
        <div class="hide fade modal" id="input-modal" role="dialog">
            <form class="form" action="/mail" method="GET">
                <input name="callback-url" type="hidden" value="contact">
                <fieldset>
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" >×</button>
                        <h3>${_('Contact Form')}</h3>
                    </div>
                    <div class="modal-body">
                        <label><b>${_('Email')} :</b></label>
                        <input class="input-xxlarge"  id="email" name="email" type="text" \
placeholder="${_(u'Type your email…')}">

                        <label><b>${_('Subject')} :</b></label>
                        <input class="input-xxlarge" id="subject" name="subject" type="text" value="${subject}">

                        <label><b>${_('Body')} :</b></label>
                        <textarea id="body" name="body">${body}</textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn" data-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary" value="send"/>Send</button>
                    </div>
                </fieldset>
            </form>
        </div>
    </div>
</%def>


<%def name="scripts_domready_content()" filter="trim">
    $(".contact-text a").on("click", function() {
        $("#input-modal").modal("show");
    });
</%def>
