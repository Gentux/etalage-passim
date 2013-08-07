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
    <p>${_(u'PASSIM content is published on <a href="http://www.data.gouv.fr/">the national open data portal</a> under <a href="http://www.data.gouv.fr/Licence-Ouverte-Open-Licence">Etalab Open Licence</a>.')}
    </p>

    <p>${_(u'''The PASSIM directory was created in 2004 as a means to give to public authorities a global vision on the traveller info service landscape and evolutions, and to contribute to some extent to a technical harmonisation ; the passim.info web site presents the directory content to the public so as they can find relevant services for any place in France, however
PASSIM main goal is to provide its content for reuse in other services and applications.''')}
    </p>

    <p>${_(u'''You may reuse PASSIM in several ways:
- the complete content is downloadable as a ZIP folder of the <a href="http://petitpois.passim.comarquage.fr/">the complete back-office content</a>, and is more complete than the content shown on the passim web site
- the content is also published in <a href="http://passim.comarquage.fr/data/">other formats easier to visualise</a>
- you may also copy and paste the html/js code for displaying in your web site the response to a particular request (via the HTML button) or download the corresponding list in CSV format (via the CSV button)
- also, the request can be made via the url via a REST API (example: /liste?term=13710+FUVEAU)''')}
    </p>

    <p>${_(u'''Please <a=href="http://passim.mat.cst.easter-eggs.com/contact">contact us</a> for any question or remark
Thank you for using PASSIM and thank in advance for your comments!''')}
    </p>


</%def>
