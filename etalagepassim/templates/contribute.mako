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
    <h2>${_('Contribute')}</h2>
    <hr>
<%
mailto_href = u'mailto:{0}?subject={1}&body={2}'.format(
    u','.join(conf['data_email']),
    _(u'Contribution to PASSIM : [new Info Service, correction to an existing Info Service...]').replace(u' ', u'%20'),
    _(u'''
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

''').strip().replace(u' ', u'%20').replace(u'\n', u'%0a'),
    )
%>\
    ${markdown.markdown(_(u'''
PASSIM is frequently verified and completed but may still include errors. If you find any false or incomplete
information, we thank you in advance for [contacting us](/contact) or
[contributing to improving the content]({mailto_href}).

You are welcome to contribute by submitting us :

* A missing information
* Any enhancement proposal
* Any correction or complement for a particular service description page

Thank you a lot ! Also, if you are interested in contributing more regularly, we may create an account for you on the
back-office content management site.
'''.format(mailto_href = mailto_href))) | n}
</%def>
