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
    <p>${_(u'PASSIM content is published on http://www.data.gouv.fr/ under Etalab Open Licence (lien http://www.data.gouv.fr/Licence-Ouverte-Open-Licence).')}
    </p>

    <p>${_(u'''The PASSIM directory was created in 2004 as a means to give to public authorities a global vision on the traveller info service landscape and evolutions, and to contribute to some extent to a technical harmonisation ; the passim.info web site presents the directory content to the public so as they can find relevant services for any place in France, however
PASSIM main goal is to provide its content for reuse in other services and applications.''')}
    </p>

    <p>${_(u'''You may reuse PASSIM in several ways:
- the complete content is downloadable as a ZIP folder (http://passim.mat.cst.easter-eggs.com/export/annuaire/csv); this is actuallty the complete back-office content (http://petitpois.passim.comarquage.fr/ link), which is more complete than the content shown on the passim web site
- the content is also published in formats easier to visualise (link http://passim.comarquage.fr/data/)
- you may also copy and paste the html/js code for displaying in your web site the response to a particular request (link) or download the corresponding list in CSV format (link)
- also, the request can be made via the url via a REST API (example: /liste?term=13710+FUVEAU)''')}
    </p>

    <p>${_(u'''Please contact us for any question or remark (link)
Thank you for using PASSIM and thank in advance for your comments!''')}
    </p>


</%def>
