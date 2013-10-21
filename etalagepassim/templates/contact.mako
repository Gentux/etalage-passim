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
    <h2>${_('Contact')}</h2>
    <hr>
<%
mailto_href = u'mailto:{0}?subject={1}&body={2}'.format(
    u','.join(conf['data_email']),
    _('Contact PASSIM : [your message subject]').replace(u' ', u'%20'),
    _(u'''
I am [an end-user, a company...]

My e-mail address: [xxx@yyy.org]

My message: ...


''').strip().replace(u' ', u'%20').replace(u'\n', u'%0a'),
    )
%>\
    ${markdown.markdown(_(u'''
[Please click here and complete this e-mail]({mailto_href}).<br>
Thank you for any question, remark or enhancement proposal.
''').format(mailto_href = mailto_href)) | n}
</%def>
