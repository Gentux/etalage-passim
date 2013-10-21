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
%>


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
    <h2>${_('Reuse')}</h2>
    <hr>
    ${markdown.markdown(_(u'''
PASSIM content is published on [the national open data portal](http://www.data.gouv.fr/) under
[Etalab Open Licence](http://www.data.gouv.fr/Licence-Ouverte-Open-Licence).

The PASSIM directory was created in 2004 as a means to give to public authorities a global vision on the traveller info
service landscape and evolutions, and to contribute to some extent to a technical harmonisation.
The passim.info web site presents the directory content to the public so that they can find relevant services for any
place in France, however PASSIM main goal is that its data content be reused by other services and applications.

You may reuse PASSIM in several ways:

* The complete content is downloadable as a ZIP folder of the
[the complete back-office content](http://petitpois.passim.comarquage.fr/), and is more complete than what is shown on
the passim web site.
* The content is also published in [other formats easier to visualise](http://passim.comarquage.fr/data/).
* You may also copy and paste the html/js code for displaying in your web site the response to a particular request
(via the HTML button) or download the corresponding list in CSV format (via the CSV button).
* Also, the request can be made via the url via a REST API (example: /liste?term=13710+FUVEAU).

Please [contact us](http://www.passim.info/contact) for any question or remark.<br>
Thank you for using PASSIM and thank in advance for your comments!
''')) | n}
</%def>
