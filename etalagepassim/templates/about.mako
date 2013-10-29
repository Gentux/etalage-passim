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
    <h4>${_('About')}</h4>
    <hr>
    ${markdown.markdown(_(u'''
The PASSIM directory lists and describes the traveller information services in France, for all transport modes.<br>
PASSIM is managed by
[the French ministry of sustainable development](http://www.developpement-durable.gouv.fr/Presentation-de-l-AFIMB.html).
<br>
The web platform is maintained by [Easter-eggs](http://www.easter-eggs.com). All software used for PASSIM is
[open source](http://gitorious.org/passim/etalage-passim).<br>
For more information: [see CETE Med web site](http://www.cete-mediterranee.fr/tt13/www/article.php3?id_article=348).

PASSIM content is published on [http://www.data.gouv.fr](http://www.data.gouv.fr) under
[Etalab Open Licence](http://www.data.gouv.fr/Licence-Ouverte-Open-Licence).

PASSIM is frequently verified and completed but may still include errors. If you find any false or incomplete
information, we thank you in advance for [contacting us](http://www.passim.info/contact) or
[contributing to improving the content](http://www.passim.info/contribute)<br>
This web site includes links towards third-party sites and services, which are provided only for your convenience.<br>
Logos and trademarks are property of their owners.
''')) | n}
</%def>
