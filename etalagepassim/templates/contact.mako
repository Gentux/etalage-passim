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


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
    <h2>${_('Contact')}</h2>
    <hr>
<%
    subject = _(
        'Contribution to PASSIM : [new Info Service, correction to an existing Info Service...]'
        ).replace(u' ', u'%20')
    body = _(u'''
I am [an end-user, a company...]

My e-mail address: [xxx@yyy.org]

Proposed contribution : [new Info Service, correction to an existing Info Service...]

Information Service

- Info Service name:
- Info booth address:
- Call centre number :
- Web site address :
- Mobile site or application :
- Transport services covered:
   - Name, Territory (city, department, region), Transport type (public transport...):
- Comments or remarks (such as information about web services, open data, real time info...):

''').strip().replace(u' ', u'%20').replace(u'\n', u'%0a')
%>\
    <p>
        <a href="mailto:${u','.join(conf['data_email'])}?subject=${subject}&body=${body}">
            ${_('Please click here and complete this e-mail')}
        </a> ${_('Thank you for any question, remark or enhancement proposal.')}
    </p>
</%def>
