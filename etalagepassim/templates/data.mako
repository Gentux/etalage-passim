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
    <h2>${_('Reuse')}</h2>
    <hr>
    <p>
        ${_(u'PASSIM content is published on ')}<a href="http://www.data.gouv.fr/">\
${_('the national open data portal')}</a>${_(' under ')}<a href="http://www.data.gouv.fr/Licence-Ouverte-Open-Licence">\
${_('Etalab Open Licence')}</a>.
    </p>

    <p>
        ${_(u'The PASSIM directory was created in 2004 as a means to give to public authorities a global vision on the \
traveller info service landscape and evolutions, and to contribute to some extent to a technical harmonisation ; \
the passim.info web site presents the directory content to the public so as they can find relevant services for any \
place in France, however PASSIM main goal is to provide its content for reuse in other services and applications.')}
    </p>

    <p>
        ${_(u'You may reuse PASSIM in several ways :')}
    </p>

    <ul>
        <li>${_('The complete content is downloadable as a ZIP folder of the ')}\
<a href="http://petitpois.passim.comarquage.fr/">${_('the complete back-office content')}</a>\
${_(', and is more complete than the content shown on the passim web site')}</li>
        <li>${_('The content is also published in ')}<a href="http://passim.comarquage.fr/data/">\
${_('other formats easier to visualise')}</a></li>
        <li>${_('You may also copy and paste the html/js code for displaying in your web site the response to a \
particular request (via the HTML button) or download the corresponding list in CSV format (via the CSV button)')}</li>
        <li>${_('Also, the request can be made via the url via a REST API (example: /liste?term=13710+FUVEAU)''')}</li>
    </ul>

    <p>
        ${_(u'Please ')}<a href="http://passim.mat.cst.easter-eggs.com/contact">${_('contact us')}</a>\
${_(' for any question or remark')}.<br>
        ${_(u'Thank you for using PASSIM and thank in advance for your comments!')}
    </p>
</%def>
