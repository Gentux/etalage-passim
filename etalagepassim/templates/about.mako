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
    <h2>${_('About')}</h2>
    <hr>
    <p>${_(u'The PASSIM directory lists and describes the traveller information services in France, for all modes of transport.<br>
PASSIM is managed by <a href="http://www.developpement-durable.gouv.fr/Presentation-de-l-AFIMB.html">the French ministry of sustainable development</a>.<br>
The web site and platform is maintained by <a href="http://www.easter-eggs.com">Easter-eggs</a>. All software used for PASSIM is <a href="http://gitorious.org/passim/etalage-passim">open source</a>.<br>
For more information: <a href="http://www.cete-mediterranee.fr/tt13/www/article.php3?id_article=348)">see CETE Med web site</a>.')}
    </p>

    <p>${_(u'PASSIM content is published on <a href="http://www.data.gouv.fr">http://www.data.gouv.fr</a> under <a href="http://www.data.gouv.fr/Licence-Ouverte-Open-Licence">Etalab Open Licence</a>.')}
    </p>
    
    <p>${_(u'PASSIM is frequently verified and completed but may still include errors. If you find any false or incomplete information, we thank you in advance for <a=href="http://passim.mat.cst.easter-eggs.com/contact">contacting us</a> or <a href="http://passim.mat.cst.easter-eggs.com/contribute">contributing to improving the content</a>. <br>
This web site includes links towards third-party sites and services, which are provided only for your convenience.
Logos and trademarks are property of their owners.')}
    </p>
</%def>
